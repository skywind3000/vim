#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# makoserver.py - PHP-like dynamic page server based on Mako + Flask
#
# Created by skywind on 2026/08/18
# Last Modified: 2026/08/18 05:45:53
#
# Serve .mako templates the way PHP serves .php files: drop files
# into a document root and every "*.mako" is rendered per request
# with PHP style superglobals (_GET / _POST / _REQUEST / _SERVER /
# _COOKIE / _SESSION / _BODY / _JSON), echo()/escape() text helpers,
# echoraw() for binary output (short-circuits text, appends to an
# independent binary buffer) and a RESP response-control object.
# Whitelisted static files are served as-is; everything else is 404
# (fail-closed).
#
# Run modes:
#
#   1. Standalone dev server:
#        python makoserver.py [-r ROOT] [-p PORT] [--host ADDR]
#                             [--conf FILE]
#      Serves ROOT (priority: -r > config "root" > cwd) on
#      http://127.0.0.1:5000 by default, e.g.:
#        python makoserver.py -r ./site -p 8080
#
#   2. WSGI application (Apache mod_wsgi / gunicorn / uWSGI):
#      Import this module and use the module-level "application"
#      object, built at import time from the config search chain;
#      root falls back to this file's directory, so copying
#      makoserver.py into the site directory is a zero-config
#      deployment, e.g.:
#        WSGIScriptAlias /app1 /path/to/makoserver.py   (Apache)
#        gunicorn makoserver:application                (gunicorn)
#
#   3. CLI rendering (like "php script.php"):
#        python makoserver.py script.mako [args...]
#        echo '<% echo(6 * 7) %>' | python makoserver.py -
#      Renders a single script and writes the raw bytes to stdout;
#      a script name of "-" reads the template source from stdin
#      (POSIX convention; includes resolve against cwd). Everything
#      after the script name is passed through verbatim as
#      _SERVER['argv'] (argv[0] = the script itself, "-" for stdin).
#      No config file is read in this mode.
#
#   4. Plain CGI script (Apache mod_cgi / mod_cgid):
#      Drop makoserver.py into cgi-bin (or map it via "Action"),
#      the CGI environment is auto-detected (GATEWAY_INTERFACE /
#      REQUEST_METHOD markers); one request is served per process
#      through wsgiref's CGIHandler. Zero-config document root
#      falls back to the server-provided DOCUMENT_ROOT; the normal
#      config search chain still applies.
#
# Configuration is a single-section INI ([makoserver]), searched in
# order: --conf FILE > env MAKOSERVER_CONF > makoserver.ini next to
# this file > ~/.config/makoserver/settings.ini (first hit wins).
# Keys: root, secret, session_lifetime, session_mode, session_cookie,
# access_log, error_log.
#
# See prd.md and spec.md in the same directory for full details.
#
#======================================================================

import sys
import os
import io
import json
import time
import html
import re
import uuid
import hmac
import base64
import socket
import hashlib
import logging
import difflib
import platform
import argparse
import posixpath
import threading
import traceback
import datetime
import configparser
import urllib.parse

import flask
from werkzeug.utils import redirect as wz_redirect
from werkzeug.exceptions import HTTPException
from mako.template import Template
from mako import runtime as mako_runtime
from mako import exceptions as mako_exceptions

__version__ = '1.0.0'

# "application" is a lazy WSGI wrapper (LazyApplication, decision
# #37): a real module-level binding (mod_wsgi resolves it by direct
# namespace dict lookup), building the actual app on first request
__all__ = ['MakoServer', 'create_app', 'application', '__version__']


#======================================================================
# Constants
#======================================================================

# Directory of this file (WSGI zero-config fallback root, and the
# anchor for the makoserver.ini config lookup)
MODULE_DIR = os.path.dirname(os.path.abspath(__file__))

# Config schema defaults (flat keys inside the [makoserver] section)
DEFAULT_CONFIG = {
    'root': '',
    'secret': '',
    'session_lifetime': 3600,
    'session_mode': 'sliding',
    'session_cookie': 'MAKO_SESSION',
    'max_body': 67108864,
    'static_types': '',
    'access_log': '',
    'error_log': '',
}

KNOWN_KEYS = list(DEFAULT_CONFIG.keys())

# Static file extension whitelist (mimetypes module rejected: its
# mappings come from the OS registry and are not under our control);
# extendable per site via the static_types config key (decision #39)
STATIC_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.htm': 'text/html; charset=utf-8',
    '.txt': 'text/plain; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.mjs': 'text/javascript; charset=utf-8',
    '.json': 'application/json',
    '.map': 'application/json',
    '.xml': 'application/xml',
    '.csv': 'text/csv; charset=utf-8',
    '.md': 'text/markdown; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.webp': 'image/webp',
    '.avif': 'image/avif',
    '.bmp': 'image/bmp',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.eot': 'application/vnd.ms-fontobject',
    '.mp3': 'audio/mpeg',
    '.ogg': 'audio/ogg',
    '.wav': 'audio/wav',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.wasm': 'application/wasm',
    '.pdf': 'application/pdf',
    '.zip': 'application/zip',
    '.rar': 'application/vnd.rar',
    '.7z': 'application/x-7z-compressed',
    '.tar': 'application/x-tar',
    '.gz': 'application/gzip',
    '.tgz': 'application/gzip',
    '.xz': 'application/x-xz',
}

# Index fallback order for directory requests
INDEX_FILES = ('index.mako', 'index.html', 'index.htm')

# All HTTP methods routed to the views
ALL_METHODS = ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS']

# Size limit of the complete session cookie string (500 when exceeded)
SESSION_COOKIE_LIMIT = 3800


#======================================================================
# Exceptions
#======================================================================

class ConfigError (Exception):
    """Bad configuration or startup argument; abort at startup."""


class SessionTooLarge (Exception):
    """Session data exceeds the cookie capacity limit."""


#======================================================================
# Configuration: lookup and loading
#======================================================================

def find_config_file (cli_conf=None):
    """Search config file by priority, first hit wins.

    Returns the absolute path or None. Order: command line --conf >
    env MAKOSERVER_CONF > makoserver.ini next to makoserver.py >
    ~/.config/makoserver/settings.ini.
    An explicit --conf pointing at a missing file is an error
    (decision #40; silently falling through to the user-level config
    would be a surprising misfire); a missing MAKOSERVER_CONF stays
    lenient (env vars leak across contexts) and keeps searching.
    """
    if cli_conf:
        if not os.path.isfile(cli_conf):
            raise ConfigError('config file not found: %s' % cli_conf)
        return os.path.abspath(cli_conf)
    candidates = []
    env_conf = os.environ.get('MAKOSERVER_CONF', '')
    if env_conf:
        candidates.append(env_conf)
    candidates.append(os.path.join(MODULE_DIR, 'makoserver.ini'))
    home = os.path.expanduser('~')
    candidates.append(os.path.join(home, '.config', 'makoserver', 'settings.ini'))
    for name in candidates:
        if name and os.path.isfile(name):
            return os.path.abspath(name)
    return None


def parse_static_types (text):
    """Parse the static_types config value ("ext=mime, ext2=mime2")
    into a dict of {'.ext': 'mime'}; raises ValueError on bad format.

    Extensions are lowercased and get a leading dot when missing;
    entries extend/override the builtin STATIC_TYPES whitelist
    (decision #39).
    """
    table = {}
    for item in str(text or '').split(','):
        item = item.strip()
        if not item:
            continue
        if '=' not in item:
            raise ValueError('bad static_types entry: %r '
                             '(expected ext=mime)' % item)
        ext, mime = item.split('=', 1)
        ext = ext.strip().lower()
        mime = mime.strip()
        if not ext or not mime:
            raise ValueError('bad static_types entry: %r '
                             '(expected ext=mime)' % item)
        if not ext.startswith('.'):
            ext = '.' + ext
        table[ext] = mime
    return table


def load_config (path):
    """Load an INI config file into a dict; raise ConfigError if bad."""
    cp = configparser.ConfigParser(interpolation=None)
    try:
        with open(path, 'r', encoding='utf-8-sig') as fp:
            cp.read_file(fp)
    except configparser.Error as e:
        raise ConfigError('config parse error in %s: %s' % (path, e))
    except OSError as e:
        raise ConfigError('cannot read config %s: %s' % (path, e))
    if not cp.has_section('makoserver'):
        raise ConfigError('missing [makoserver] section in %s' % path)
    conf = dict(DEFAULT_CONFIG)
    for key, value in cp.items('makoserver'):
        if key in KNOWN_KEYS:
            conf[key] = value
        else:
            # unknown keys are ignored; warn when close to a known key
            # so a typo does not silently fall back to the default
            close = difflib.get_close_matches(key, KNOWN_KEYS, n=1, cutoff=0.8)
            if close:
                sys.stderr.write('makoserver: warning: unknown config key %r '
                                 '(did you mean %r?) in %s\n' % (key, close[0], path))
    # explicit int conversion for session_lifetime
    try:
        conf['session_lifetime'] = int(str(conf['session_lifetime']).strip())
    except ValueError:
        raise ConfigError('session_lifetime must be an integer in %s' % path)
    if conf['session_lifetime'] <= 0:
        # 0/negative would make every session instantly expired --
        # silently unusable; error out (decision #22 philosophy)
        raise ConfigError('session_lifetime must be positive in %s' % path)
    # explicit int conversion for max_body (request body size limit
    # in bytes; <= 0 means unlimited)
    try:
        conf['max_body'] = int(str(conf['max_body']).strip())
    except ValueError:
        raise ConfigError('max_body must be an integer in %s' % path)
    # validate static_types format at startup (fail fast); the parsed
    # table is rebuilt by MakoServer from the same string
    try:
        parse_static_types(conf.get('static_types', ''))
    except ValueError as e:
        raise ConfigError('%s in %s' % (e, path))
    # validate session_mode
    mode = str(conf['session_mode']).strip().lower()
    if mode not in ('sliding', 'absolute'):
        raise ConfigError('session_mode must be sliding or absolute in %s' % path)
    conf['session_mode'] = mode
    # relative paths are resolved against the config file's directory
    conf_dir = os.path.dirname(os.path.abspath(path))
    for key in ('root', 'access_log', 'error_log'):
        value = str(conf[key]).strip()
        if value and not os.path.isabs(value):
            value = os.path.abspath(os.path.join(conf_dir, value))
        conf[key] = value
    conf['secret'] = str(conf['secret']).strip()
    conf['session_cookie'] = str(conf['session_cookie']).strip() or 'MAKO_SESSION'
    return conf


def validate_startup (config, root, source):
    """Startup validation: root must be an existing directory; log
    paths must have an existing parent directory and be appendable.

    Raises ConfigError on failure (failing fast beats limping along).
    """
    if not os.path.isdir(root):
        raise ConfigError('root=%s (from %s) is not a directory' % (root, source))
    for key in ('error_log', 'access_log'):
        path = config.get(key) or ''
        if not path:
            continue
        parent = os.path.dirname(os.path.abspath(path))
        if not os.path.isdir(parent):
            raise ConfigError('%s directory not found: %s (from %s)' % (key, parent, source))
        try:
            fp = open(path, 'a', encoding='utf-8')
            fp.close()
        except OSError as e:
            raise ConfigError('%s cannot open for append: %s (%s)' % (key, path, e))


#======================================================================
# Logging
#======================================================================

class _AppendFileHandler (logging.Handler):
    """Open the file in append mode for every record; never keep the
    handle open.

    Avoids holding a long-term lock on the log file under Windows
    (which hinders cleanup/rotation); write volume is tiny in the
    local-machine scenario, so the overhead is negligible.
    """

    def __init__ (self, path):
        super(_AppendFileHandler, self).__init__()
        self.__path = path

    def emit (self, record):
        try:
            with open(self.__path, 'a', encoding='utf-8') as fp:
                fp.write(self.format(record) + '\n')
        except OSError:
            pass


def make_error_logger (path):
    """Build the error-log logger: file when configured, else stderr.

    Instantiate logging.Logger directly (bypassing the getLogger
    registry) so multiple MakoServer instances in one process (e.g.
    the test suite) do not overwrite each other's handlers.
    """
    logger = logging.Logger('makoserver.error')
    logger.setLevel(logging.DEBUG)
    logger.propagate = False
    if path:
        handler = _AppendFileHandler(path)
    else:
        handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    logger.addHandler(handler)
    return logger


def wsgi_to_utf8 (value):
    """PEP 3333 decoding dance: restore an environ carrier string
    (latin-1) back to UTF-8 text.

    Any Location built from raw environ values (SCRIPT_NAME /
    PATH_INFO) must go through this first: werkzeug's redirect()
    re-percent-encodes as UTF-8, so feeding it the latin-1 carrier
    form turns non-ASCII paths into mojibake Locations
    (%C3%A4%C2%B8%C2%AD instead of %E4%B8%AD). werkzeug performs the
    same restoration internally for request.path / script_root, so
    branches reading those are unaffected. If the value cannot be
    represented in latin-1 (e.g. tests injecting real strings), it
    is returned unchanged.
    """
    try:
        return value.encode('latin-1').decode('utf-8', 'replace')
    except UnicodeError:
        return value


class PathInfoNormMiddleware:
    """Front WSGI middleware: PATH_INFO normalization + duplicate
    slash merge redirect.

    Two jobs:
    1. Werkzeug 2.2's matcher answers an empty PATH_INFO (mount-root
       request without a slash, e.g. http://host/app1 under
       WSGIScriptAlias /app1) with its own 308 to script_root + '/'
       and drops the query, so the request never reaches the view.
       Normalize empty/bare PATH_INFO to '/' (recording the original
       value in MAKO_RAW_PATH_INFO) so the view can issue the 301 per
       spec 3.3 (query preserved);
    2. Duplicate slash merge: werkzeug's merge_slashes only kicks in
       after a first match failure, but our catch-all <path:> route
       matches on the first try (//a hits directly), so the merge 308
       never fires and cache keys diverge from the REQUEST_URI
       presentation. Merge explicitly here: //a///b -> 308 to /a/b
       (query preserved), matching the behavior declared in spec 3.1.
    """

    def __init__ (self, app):
        self.__app = app

    def __call__ (self, environ, start_response):
        path_info = environ.get('PATH_INFO', '')
        if path_info == '' or not path_info.startswith('/'):
            # record the original value in MAKO_RAW_PATH_INFO; the view
            # uses it to detect a mount-root request without a slash
            environ['MAKO_RAW_PATH_INFO'] = path_info
            path_info = '/' + path_info.lstrip('/')
            environ['PATH_INFO'] = path_info
        if '//' in path_info:
            merged = re.sub('/{2,}', '/', path_info)
            location = wsgi_to_utf8(environ.get('SCRIPT_NAME', '') + merged)
            qs = environ.get('QUERY_STRING', '')
            if qs:
                location += '?' + qs
            resp = wz_redirect(location, code=308)
            return resp(environ, start_response)
        return self.__app(environ, start_response)


class AccessLogMiddleware:
    """WSGI middleware: write the access log when access_log is set.

    Line format: {iso_time} {remote_addr} {method} {path} {status} {bytes}
    Wrapped around app.wsgi_app, so it works identically in both the
    dev server and WSGI modes.
    """

    def __init__ (self, app, path):
        self.__app = app
        self.__path = path
        self.__lock = threading.Lock()

    def __call__ (self, environ, start_response):
        meta = {'status': '-', 'bytes': '-'}

        def capture (status, headers, exc_info=None):
            meta['status'] = str(status).split(' ', 1)[0]
            for name, value in headers:
                if str(name).lower() == 'content-length':
                    meta['bytes'] = str(value)
            return start_response(status, headers, exc_info)
        try:
            result = self.__app(environ, capture)
        except BaseException:
            # an exception escaping the app must not make the request
            # vanish from the access log: record it as 500, re-raise
            meta['status'] = '500'
            self.__write_line(environ, meta)
            raise
        self.__write_line(environ, meta)
        return result

    def __write_line (self, environ, meta):
        try:
            uri = environ.get('REQUEST_URI') or environ.get('RAW_URI')
            if not uri:
                uri = environ.get('SCRIPT_NAME', '') + environ.get('PATH_INFO', '')
                qs = environ.get('QUERY_STRING', '')
                if qs:
                    uri += '?' + qs
            line = '%s %s %s %s %s %s\n' % (
                datetime.datetime.now().isoformat(timespec='seconds'),
                environ.get('REMOTE_ADDR', '-'),
                environ.get('REQUEST_METHOD', '-'),
                uri, meta['status'], meta['bytes'])
            with self.__lock:
                with open(self.__path, 'a', encoding='utf-8') as fp:
                    fp.write(line)
        except OSError:
            pass


#======================================================================
# Template loading: TemplateStore
#======================================================================

class TemplateStore:
    """Custom template collection: mtime_ns + size cache (checked per
    request; no watchdog dependency), utf-8-sig reading (Windows
    notepad BOM) and a pinned not-found error shape.

    Implements the Mako collection protocol get_template(uri) /
    adjust_uri(uri, relativeto).
    """

    def __init__ (self, base_dir):
        self.base_dir = base_dir
        self.__cache = {}
        self.__lock = threading.Lock()

    def get_template (self, uri):
        path = os.path.join(self.base_dir, *uri.split('/'))
        with self.__lock:
            try:
                st = os.stat(path)
            except OSError:
                raise mako_exceptions.TopLevelLookupException(
                    'template not found: %s' % uri)
            entry = self.__cache.get(uri)
            if entry is not None and entry[1] == st.st_mtime_ns \
                    and entry[2] == st.st_size:
                return entry[3]
            try:
                with open(path, 'r', encoding='utf-8-sig') as fp:
                    text = fp.read()
            except OSError:
                raise mako_exceptions.TopLevelLookupException(
                    'template not found: %s' % uri)
            # source is kept verbatim (no rstrip): text templates
            # faithfully preserve the trailing newline of the source
            # file; binary scripts go through RESP.writeraw/echoraw
            # which short-circuits all text output anyway
            # filename= does NOT set __file__ in module blocks and
            # does NOT change runtime traceback frames (Mako compiles
            # with co_filename = mangled module_id, decision #28);
            # its one verified effect: compile-phase SyntaxException
            # messages gain an "in file '<abs path>'" clause, which
            # flows into the 500 page / CLI stderr / error log
            tpl = Template(text=text, lookup=self, uri=uri,
                           filename=path, input_encoding='utf-8')
            self.__cache[uri] = (path, st.st_mtime_ns, st.st_size, tpl)
            return tpl

    def adjust_uri (self, uri, relativeto):
        if uri.startswith('/'):
            return uri
        if relativeto is None:
            return uri
        return posixpath.normpath(
            posixpath.join(posixpath.dirname(relativeto), uri))


#======================================================================
# Output helpers: echo / escape
#======================================================================

def make_echo (buf):
    """Build echo(*args): mimic PHP echo, text only; None prints
    nothing, other values are str()-ed; bytes-like raises TypeError
    (binary output goes through RESP.writeraw/echoraw).

    The writer is late-bound: echo starts on buf.write and is
    re-targeted to Context.write via echo.bind(ctx.write) once the
    Mako Context exists, so echo output respects the context buffer
    stack -- capture(), buffered defs and filter= modifiers all see
    it -- instead of leaking straight into the bottom buffer (spec
    decision #33).
    """
    state = [buf.write]

    def echo (*args):
        write = state[0]
        for item in args:
            if item is None:
                continue
            if isinstance(item, str):
                write(item)
            elif isinstance(item, (bytes, bytearray, memoryview)):
                raise TypeError(
                    'echo() accepts text only; use '
                    'RESP.writeraw()/echoraw() for binary output')
            else:
                write(str(item))

    def bind (writer):
        state[0] = writer
    echo.bind = bind
    return echo


def html_escape (value):
    """escape(value): mimic PHP htmlspecialchars, returning the
    escaped string.

    str() the value, then escape & < > " ' (quote=True); if str()
    fails, return '(unprintable)'. Pure conversion function with no
    output; behaves the same in HTTP and CLI modes.
    """
    try:
        return html.escape(str(value), quote=True)
    except Exception:
        return '(unprintable)'


#======================================================================
# Bridge: PHPDict / RespObject
#======================================================================

class PHPDict (dict):
    """PHP-superglobal-like dict: the single value is the last
    occurrence of a repeated parameter; getlist returns all of them."""

    def __init__ (self, *args, **kwargs):
        super(PHPDict, self).__init__(*args, **kwargs)
        self.__lists = {}

    def setlist (self, name, values):
        self.__lists[name] = list(values)

    def getlist (self, name):
        return list(self.__lists.get(name, []))

    @staticmethod
    def from_multidict (md):
        d = PHPDict()
        for key in md.keys():
            values = md.getlist(key)
            d[key] = values[-1]
            d.setlist(key, values)
        return d


def merge_php_dict (get_d, post_d):
    """Merge into _REQUEST: POST overrides same-name GET; getlist
    returns all GET+POST values."""
    d = PHPDict()
    for key, value in get_d.items():
        d[key] = value
    for key, value in post_d.items():
        d[key] = value
    for key in get_d.keys():
        d.setlist(key, get_d.getlist(key) + post_d.getlist(key))
    for key in post_d.keys():
        if key not in get_d:
            d.setlist(key, post_d.getlist(key))
    return d


class RespObject:
    """Response control object (RESP):
    header/status/redirect/json/setcookie/write/writeraw.

    In CLI mode header/status/redirect/setcookie are no-ops;
    write/writeraw/json output normally (output, not response
    control).
    """

    def __init__ (self, echo_func, cli=False):
        self.__echo = echo_func
        self.__cli = cli
        self.__headers = []     # (name, value) list; Set-Cookie appends, others overwrite
        self.__status = None
        self.__cookies = {}     # name -> full cookie string, same name overwrites
        self.__raw_chunks = []  # independent binary buffer (writeraw)
        self.__raw_used = False
        # canonical names as instance attributes: RESP.write IS the
        # very same function object as the injected echo (and
        # RESP.escape the same as escape) -- shadowing-proof fallback
        self.write = echo_func
        self.escape = html_escape

    def writeraw (self, *args):
        """Append bytes-like args to the independent binary buffer.
        Once called, the raw bytes short-circuit all text output
        (template text blocks and echo) and become the whole body;
        Content-Type is NOT set here, the script must set it via
        RESP.header() itself."""
        self.__raw_used = True
        for item in args:
            if isinstance(item, (bytes, bytearray, memoryview)):
                self.__raw_chunks.append(bytes(item))
            else:
                raise TypeError(
                    'writeraw() accepts bytes-like only; use '
                    'echo()/RESP.write() for text output')

    def header (self, name, value):
        if self.__cli:
            return
        name = str(name)
        lower = name.lower()
        if lower == 'set-cookie':
            self.__headers.append((name, str(value)))
            return
        for i, item in enumerate(self.__headers):
            if item[0].lower() == lower:
                self.__headers[i] = (name, str(value))
                return
        self.__headers.append((name, str(value)))

    def status (self, code):
        if self.__cli:
            return
        code = int(code)
        if code < 100 or code > 599:
            # out-of-range codes break WSGI hosts/clients in
            # unpredictable ways -- fail fast (-> 500)
            raise ValueError('status code out of range: %d' % code)
        self.__status = code

    def redirect (self, url, code=302):
        self.header('Location', url)
        self.status(code)

    def json (self, data):
        text = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
        if not self.__cli:
            self.header('Content-Type', 'application/json')
        self.__echo(text)

    def setcookie (self, name, value='', *, max_age=None, expires=None,
                   path='/', domain=None, secure=False, httponly=False,
                   samesite=None):
        if self.__cli:
            return
        # the cookie VALUE is percent-encoded (RFC 3986 quote, space
        # becomes %20 -- deliberately NOT PHP urlencode's '+'), the
        # semantic counterpart of PHP setcookie() which encodes by
        # default (raw values with ; , = or spaces would be
        # truncated/corrupted by cookie syntax); _COOKIE decodes on
        # read (spec decision #31). The raw escape hatch is
        # RESP.header('Set-Cookie', ...), equivalent to PHP
        # setrawcookie()
        parts = ['%s=%s' % (name, urllib.parse.quote(str(value), safe=''))]
        if expires is not None:
            if isinstance(expires, datetime.datetime):
                # naive datetimes are taken as UTC (Werkzeug http_date
                # convention); aware ones are normalized to UTC
                if expires.tzinfo is None:
                    stamp = expires.replace(tzinfo=datetime.timezone.utc)
                else:
                    stamp = expires.astimezone(datetime.timezone.utc)
                parts.append('Expires=' + stamp.strftime('%a, %d %b %Y %H:%M:%S GMT'))
            elif isinstance(expires, (int, float)):
                # fromtimestamp + utc tz (utcfromtimestamp deprecated in 3.12)
                stamp = datetime.datetime.fromtimestamp(
                    expires, datetime.timezone.utc)
                parts.append('Expires=' + stamp.strftime('%a, %d %b %Y %H:%M:%S GMT'))
            else:
                # anything else would emit an invalid cookie date that
                # browsers silently ignore -- fail fast instead;
                # a preformatted IMF-fixdate string passes through
                if isinstance(expires, str):
                    parts.append('Expires=%s' % expires)
                else:
                    raise TypeError(
                        'setcookie() expires must be an int/float '
                        'timestamp, a datetime or a preformatted string')
        if max_age is not None:
            parts.append('Max-Age=%d' % int(max_age))
        if path:
            parts.append('Path=%s' % path)
        if domain:
            parts.append('Domain=%s' % domain)
        if secure:
            parts.append('Secure')
        if httponly:
            parts.append('HttpOnly')
        if samesite:
            parts.append('SameSite=%s' % samesite)
        self.__cookies[str(name)] = '; '.join(parts)

    def collect (self):
        """Fetch internal state at assembly time: (status, headers, cookies)."""
        return (self.__status, list(self.__headers), dict(self.__cookies))

    def collect_raw (self):
        """Fetch the raw output state at assembly time:
        (raw_used, raw_bytes)."""
        return (self.__raw_used, b''.join(self.__raw_chunks))


#======================================================================
# Session: signed cookie codec and key derivation
#======================================================================

_HOST_SECRET = None


def derive_host_secret ():
    """Derive the session signing key from the host fingerprint
    (module-level cache, computed once per process).

    Multi-component collection (hostname / motherboard UUID or
    machine-id / CPU / MAC), each fault-tolerant on its own;
    sha256(':'.join(components)) is used directly as the
    HMAC-SHA256 key.
    """
    global _HOST_SECRET
    if _HOST_SECRET is not None:
        return _HOST_SECRET
    components = ['MAKOSERVER-HOST-KEY']
    try:
        components.append(socket.gethostname())
    except Exception:
        pass
    if os.name == 'nt':
        got = False
        try:
            import subprocess
            proc = subprocess.run(['wmic', 'csproduct', 'get', 'uuid'],
                                  capture_output=True, timeout=10)
            out = proc.stdout.decode('utf-8', 'ignore')
            for line in out.splitlines():
                line = line.strip()
                if line and not line.upper().startswith('UUID'):
                    components.append(line)
                    got = True
                    break
        except Exception:
            pass
        if not got:
            try:
                import winreg
                key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                     r'SOFTWARE\Microsoft\Cryptography')
                try:
                    value = winreg.QueryValueEx(key, 'MachineGuid')[0]
                    components.append(str(value))
                finally:
                    winreg.CloseKey(key)
            except Exception:
                pass
    else:
        for name in ('/etc/machine-id', '/var/lib/dbus/machine-id',
                     '/sys/class/dmi/id/product_uuid'):
            try:
                with open(name, 'r', encoding='ascii', errors='ignore') as fp:
                    value = fp.read().strip()
                if value:
                    components.append(value)
                    break
            except Exception:
                pass
    try:
        value = platform.processor()
        if value:
            components.append(value)
    except Exception:
        pass
    try:
        skip = False
        try:
            with open('/proc/version', 'r', encoding='ascii', errors='ignore') as fp:
                pv = fp.read().lower()
            if ('microsoft' in pv) or ('wsl' in pv):
                skip = True
        except Exception:
            pass
        if not skip:
            mac = uuid.getnode()
            # bit 40 is the locally-administered bit; 1 means a
            # random/local MAC, unstable, skip it
            if ((mac >> 40) & 0x01) == 0:
                components.append('%012x' % mac)
    except Exception:
        pass
    text = ':'.join(components)
    _HOST_SECRET = hashlib.sha256(text.encode('utf-8', 'ignore')).digest()
    return _HOST_SECRET


class SessionCodec:
    """Signed session cookie codec.

    Format: {data_b64}.{ts}.{sig}
    sig = hmac_sha256(secret, data_b64 + '.' + ts).hexdigest()
    """

    def __init__ (self, secret, lifetime, mode, cookie_name):
        self.secret = secret
        self.lifetime = lifetime
        self.mode = mode
        self.cookie_name = cookie_name

    def encode (self, data, ts):
        payload = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
        data_b64 = base64.urlsafe_b64encode(payload.encode('utf-8')).rstrip(b'=')
        ts_s = str(int(ts)).encode('ascii')
        sig = hmac.new(self.secret, data_b64 + b'.' + ts_s,
                       hashlib.sha256).hexdigest()
        return (data_b64 + b'.' + ts_s + b'.' + sig.encode('ascii')).decode('ascii')

    def decode (self, value, now=None):
        """Verify the cookie; return (data_dict, ts) on success, else None."""
        if not value or not isinstance(value, str):
            return None
        if now is None:
            now = int(time.time())
        parts = value.split('.')
        if len(parts) != 3:
            return None
        try:
            data_b64 = parts[0].encode('ascii')
            ts_s = parts[1].encode('ascii')
            sig = parts[2]
            ts = int(parts[1])
        except (UnicodeEncodeError, ValueError):
            return None
        expect = hmac.new(self.secret, data_b64 + b'.' + ts_s,
                          hashlib.sha256).hexdigest()
        try:
            if not hmac.compare_digest(sig, expect):
                return None
        except TypeError:
            return None
        if now - ts >= self.lifetime:
            return None
        pad = data_b64 + b'=' * (-len(data_b64) % 4)
        try:
            data = json.loads(base64.urlsafe_b64decode(pad).decode('utf-8'))
        except Exception:
            return None
        if not isinstance(data, dict):
            return None
        return (data, ts)


#======================================================================
# MakoServer: request processing pipeline
#======================================================================

class MakoServer:
    """Core server object: holds root / config / TemplateStore /
    blocked path set and other state."""

    def __init__ (self, root, config, conf_path=None):
        self.root = os.path.abspath(root)
        self.root_real = os.path.realpath(self.root)
        self.config = dict(config)
        self.conf_path = conf_path
        self.store = TemplateStore(self.root)
        if config.get('secret'):
            secret = config['secret'].encode('utf-8')
        else:
            # per-site key (decision #34): mix the document root into
            # the host fingerprint so co-hosted sites (other mounts /
            # ports on the same machine) cannot validate or forge each
            # other's session cookies; an explicit secret in the
            # config keeps full control (deliberate sharing possible)
            secret = hmac.new(derive_host_secret(),
                              os.path.normcase(self.root_real).encode('utf-8'),
                              hashlib.sha256).digest()
        self.codec = SessionCodec(secret, config['session_lifetime'],
                                  config['session_mode'], config['session_cookie'])
        # per-site static whitelist: builtin table extended/overridden
        # by the static_types config key (already validated at load
        # time, decision #39)
        self.static_types = dict(STATIC_TYPES)
        self.static_types.update(parse_static_types(config.get('static_types', '')))
        # runtime sensitive-path block set (stores normcase(realpath))
        self.blocked = set()
        if conf_path:
            self.blocked.add(os.path.normcase(os.path.realpath(conf_path)))
        for key in ('error_log', 'access_log'):
            if config.get(key):
                self.blocked.add(os.path.normcase(os.path.realpath(config[key])))
        self.error_logger = make_error_logger(config.get('error_log') or None)

    #----------------------------------------------------------------------
    # small helpers
    #----------------------------------------------------------------------

    def __not_found (self):
        return flask.Response('404 Not Found\n', status=404,
                              content_type='text/plain; charset=utf-8')

    def __method_not_allowed (self):
        resp = flask.Response('405 Method Not Allowed\n', status=405,
                              content_type='text/plain; charset=utf-8')
        resp.headers['Allow'] = 'GET, HEAD'
        return resp

    def __internal_error (self):
        tb = traceback.format_exc()
        try:
            path = flask.request.path
        except RuntimeError:
            path = ''
        self.error_logger.error('internal error for %s\n%s', path, tb)
        body = '<h1>500 Internal Server Error</h1>\n<p>%s</p>\n<pre>%s</pre>\n' % (
            html.escape(path), html.escape(tb))
        return flask.Response(body, status=500,
                              content_type='text/html; charset=utf-8')

    def internal_error (self):
        """Public entry to the framework 500 fallback (used by the
        view-level catch-all, decision #35): logs the traceback to
        the error log and builds the spec 9.1 error page."""
        return self.__internal_error()

    def __is_blocked (self, real):
        return os.path.normcase(real) in self.blocked

    def __within_root (self, real):
        """realpath containment: real must live inside root_real (or
        be root_real itself)."""
        try:
            common = os.path.commonpath([os.path.normcase(real),
                                         os.path.normcase(self.root_real)])
        except ValueError:
            return False
        return common == os.path.normcase(self.root_real)

    #----------------------------------------------------------------------
    # entry: branch decision
    #----------------------------------------------------------------------

    def handle (self, url_path):
        """Handle one request; url_path is the URL tail extracted by
        the route (already URL-decoded)."""
        # spec 3.2 step 1: POSIX normalization
        rel = posixpath.normpath('/' + url_path).lstrip('/')
        trailing = url_path.endswith('/')
        # spec 3.2 step 2: reject NUL bytes
        if '\x00' in rel:
            return self.__not_found()
        # spec 3.2 step 3: NT special-casing (intentional cross-platform split)
        if os.name == 'nt':
            if ':' in rel:
                return self.__not_found()
            rel = rel.rstrip(' .')
        # spec 3.2 step 4: join and realpath containment
        if rel:
            full = os.path.join(self.root_real, rel.replace('/', os.sep))
        else:
            full = self.root_real
        try:
            real = os.path.realpath(full)
        except (OSError, ValueError):
            return self.__not_found()
        if not self.__within_root(real):
            return self.__not_found()
        # spec 3.2 step 5: sensitive path blocking (fast path on the
        # initial real)
        if self.__is_blocked(real):
            return self.__not_found()
        # spec 3.3 branch decision (basename explicitly lower()-ed:
        # case-insensitive on every platform)
        name = os.path.basename(real).lower()
        if name.endswith('.mako'):
            if os.path.isfile(real):
                # a bare trailing slash counts as path info:
                # /demo.mako/ -> PATH_INFO='/'
                path_info = '/' if trailing else ''
                return self.__render(real, rel, '/' + rel, path_info)
            return self.__not_found()
        if os.path.isfile(real):
            if trailing:
                # file path with a trailing slash -> 404 (align Apache)
                return self.__not_found()
            return self.__serve_static(real)
        if os.path.isdir(real):
            return self.__serve_dir(real, rel)
        return self.__walk_back(real, trailing)

    #----------------------------------------------------------------------
    # static branch
    #----------------------------------------------------------------------

    def __serve_static (self, real):
        base = os.path.basename(real).lower()
        ext = os.path.splitext(base)[1]
        ctype = self.static_types.get(ext)
        if ctype is None:
            # outside the whitelist -> 404 (fail-closed, same response
            # as a missing file)
            return self.__not_found()
        if flask.request.method not in ('GET', 'HEAD'):
            return self.__method_not_allowed()
        try:
            with open(real, 'rb') as fp:
                data = fp.read()
        except OSError:
            return self.__internal_error()
        return flask.Response(data, status=200, content_type=ctype)

    #----------------------------------------------------------------------
    # directory branch: 301 slash redirect + index fallback
    #----------------------------------------------------------------------

    def __serve_dir (self, real, rel):
        req = flask.request
        environ = req.environ
        # mount root without a slash (original PATH_INFO empty) -> 301
        raw_pi = environ.get('MAKO_RAW_PATH_INFO', environ.get('PATH_INFO', ''))
        if raw_pi == '' and environ.get('SCRIPT_NAME', ''):
            location = wsgi_to_utf8(environ['SCRIPT_NAME']) + '/'
            qs = environ.get('QUERY_STRING', '')
            if qs:
                location += '?' + qs
            return wz_redirect(location, code=301)
        # directory request without a trailing slash -> 301 (align
        # Apache DirectorySlash)
        if not req.path.endswith('/'):
            location = req.script_root + req.path + '/'
            qs = environ.get('QUERY_STRING', '')
            if qs:
                location += '?' + qs
            return wz_redirect(location, code=301)
        # index fallback: index.mako / index.html / index.htm
        for fn in INDEX_FILES:
            cand = os.path.join(real, fn)
            cand_real = os.path.realpath(cand)
            if not os.path.isfile(cand_real):
                continue
            if not self.__within_root(cand_real):
                continue
            if self.__is_blocked(cand_real):
                return self.__not_found()
            if fn == 'index.mako':
                script_rel = (rel + '/index.mako') if rel else 'index.mako'
                suffix = ('/' + rel + '/') if rel else '/'
                return self.__render(cand_real, script_rel, suffix, '')
            # index.html / index.htm go static (exempt from trailing,
            # still under the method restriction)
            return self.__serve_static(cand_real)
        return self.__not_found()

    #----------------------------------------------------------------------
    # path-info walk-back (PATH_INFO mechanism, align PHP AcceptPathInfo)
    #----------------------------------------------------------------------

    def __walk_back (self, real, trailing):
        current = real
        suffix_parts = []
        root_norm = os.path.normcase(self.root_real)
        while True:
            if os.path.normcase(current) == root_norm:
                return self.__not_found()
            parent = os.path.dirname(current)
            if parent == current or not parent:
                return self.__not_found()
            suffix_parts.insert(0, os.path.basename(current))
            current = parent
            if os.path.isfile(current):
                base = os.path.basename(current).lower()
                if not base.endswith('.mako'):
                    # static files take no path info
                    return self.__not_found()
                if self.__is_blocked(current):
                    return self.__not_found()
                path_info = '/' + '/'.join(suffix_parts)
                if trailing:
                    path_info += '/'
                rel_target = os.path.relpath(current, self.root_real)
                rel_target = rel_target.replace(os.sep, '/')
                return self.__render(current, rel_target, '/' + rel_target,
                                     path_info)
            if os.path.isdir(current):
                # walk-back hit an existing directory -> 404 (no index
                # fallback, align Apache mod_dir)
                return self.__not_found()

    #----------------------------------------------------------------------
    # template branch: render + response assembly
    #----------------------------------------------------------------------

    def __render (self, script_path, script_rel, script_suffix, path_info):
        try:
            tpl = self.store.get_template(script_rel)
        except Exception:
            return self.__internal_error()
        buf = io.StringIO()
        echo = make_echo(buf)
        resp = RespObject(echo)
        bridge, session_state, session_dict = self.__build_bridge(
            echo, resp, script_path, script_suffix, path_info)
        try:
            # public Mako API only: the documented "using the Context
            # programmatically" pattern (Context + render_context);
            # echo is re-bound to ctx.write so it follows the buffer
            # stack (capture / buffered / filtered defs, decision #33)
            ctx = mako_runtime.Context(buf, **bridge)
            echo.bind(ctx.write)
            tpl.render_context(ctx)
        except SystemExit as e:
            # PHP exit()/die() muscle memory (decision #36): exit code
            # 0/None terminates rendering normally and keeps the
            # buffered output; anything else is an error -> 500
            if e.code not in (None, 0):
                return self.__internal_error()
        except Exception:
            # discard partial output, return a clean 500
            return self.__internal_error()
        # render succeeded: session finalization + response assembly
        try:
            session_cookie = self.__finalize_session(session_state, session_dict)
        except (SessionTooLarge, TypeError, ValueError):
            return self.__internal_error()
        return self.__assemble(buf, resp, session_cookie)

    def __build_bridge (self, echo, resp, script_path, script_suffix, path_info):
        """Build the bridge names. _BODY must be built first
        (get_data before form)."""
        req = flask.request
        environ = req.environ
        body = req.get_data(cache=True)
        get_d = PHPDict.from_multidict(req.args)
        post_d = PHPDict.from_multidict(req.form)
        request_d = merge_php_dict(get_d, post_d)

        server = {}
        for key in ('REQUEST_METHOD', 'QUERY_STRING', 'CONTENT_TYPE',
                    'CONTENT_LENGTH', 'REMOTE_ADDR', 'SERVER_NAME',
                    'SERVER_PORT', 'SERVER_PROTOCOL'):
            if key in environ:
                server[key] = environ[key]
        server['REQUEST_SCHEME'] = environ.get('wsgi.url_scheme', 'http')
        # PHP staples: request start time and the HTTPS marker
        now = time.time()
        server['REQUEST_TIME'] = int(now)
        server['REQUEST_TIME_FLOAT'] = now
        if server['REQUEST_SCHEME'] == 'https':
            server['HTTPS'] = 'on'
        for key, value in environ.items():
            if key.startswith('HTTP_') and isinstance(value, str):
                server[key] = value
        # REQUEST_URI: encoded original, three-level fallback
        request_uri = environ.get('REQUEST_URI') or environ.get('RAW_URI')
        if not request_uri:
            request_uri = environ.get('SCRIPT_NAME', '') + environ.get('PATH_INFO', '')
            qs = environ.get('QUERY_STRING', '')
            if qs:
                request_uri += '?' + qs
        server['REQUEST_URI'] = request_uri
        # SCRIPT_NAME / PATH_INFO rebuilt from the branch decision
        prefix = environ.get('SCRIPT_NAME', '')
        server['SCRIPT_NAME'] = prefix + script_suffix
        server['PATH_INFO'] = path_info
        script_abs = os.path.abspath(script_path)
        server['SCRIPT_FILENAME'] = script_abs
        server['DOCUMENT_ROOT'] = self.root_real
        server['SCRIPT_DIRNAME'] = os.path.dirname(script_abs)

        # _JSON: parsed only when Content-Type contains the substring
        # "json"; None on failure
        json_data = None
        ctype = (req.content_type or '').lower()
        if body and ('json' in ctype):
            try:
                json_data = json.loads(body.decode('utf-8'))
            except Exception:
                json_data = None

        # session loading
        cookie_value = req.cookies.get(self.codec.cookie_name)
        session_state = {'valid': False, 'ts': 0, 'snapshot': None}
        session_dict = {}
        if cookie_value:
            decoded = self.codec.decode(cookie_value)
            if decoded is not None:
                session_dict, ts = decoded
                session_state['valid'] = True
                session_state['ts'] = ts
                session_state['snapshot'] = json.dumps(
                    session_dict, sort_keys=True, separators=(',', ':'))

        # _COOKIE values are percent-decoded (the counterpart of PHP
        # $_COOKIE urldecode, paired with RESP.setcookie encoding);
        # a literal '+' is kept as-is, deliberately NOT decoded to a
        # space like PHP does (protects third-party base64 cookies
        # with raw '+', spec decision #31); the session codec reads
        # request.cookies directly and is not affected
        cookie_d = {}
        for key in req.cookies:
            cookie_d[key] = urllib.parse.unquote(req.cookies[key])

        bridge = {
            'echo': echo,
            'echoraw': resp.writeraw,
            'escape': html_escape,
            '_REQUEST': request_d,
            '_BODY': body,
            '_GET': get_d,
            '_POST': post_d,
            '_SERVER': server,
            '_JSON': json_data,
            '_COOKIE': cookie_d,
            '_SESSION': session_dict,
            'RESP': resp,
        }
        return bridge, session_state, session_dict

    def __finalize_session (self, state, session_dict):
        """After rendering, decide whether to send Set-Cookie per the
        sliding/absolute rules.

        Returns the full cookie string or None; may raise
        SessionTooLarge / TypeError.
        """
        # canonical JSON string deep-compare (detects in-place edits
        # at nested levels)
        dump = json.dumps(session_dict, sort_keys=True, separators=(',', ':'))
        if state['valid']:
            if self.codec.mode == 'sliding':
                ts = int(time.time())
            else:
                if dump == state['snapshot']:
                    return None
                ts = state['ts']
        else:
            if not session_dict:
                return None
            ts = int(time.time())
        value = self.codec.encode(session_dict, ts)
        cookie = '%s=%s; Path=/; HttpOnly; SameSite=Lax' % (
            self.codec.cookie_name, value)
        if len(cookie.encode('utf-8')) > SESSION_COOKIE_LIMIT:
            raise SessionTooLarge(
                'session data exceeds the cookie capacity limit (about 4KB)')
        return cookie

    def __assemble (self, buf, resp, session_cookie):
        status, headers, cookies = resp.collect()
        if status is None:
            status = 200
        content_type = None
        header_list = []
        raw_setcookies = []
        for name, value in headers:
            lower = name.lower()
            if lower == 'content-type':
                content_type = value
            elif lower == 'set-cookie':
                raw_setcookies.append(value)
            else:
                header_list.append((name, value))
        if content_type is None:
            content_type = 'text/html; charset=utf-8'
        # the session cookie name is exclusive: same-name setcookie
        # entries from the script are dropped, never sent
        session_name = self.codec.cookie_name
        for name in cookies:
            if name == session_name:
                self.error_logger.warning(
                    'setcookie(%r) conflicts with the reserved session '
                    'cookie name, dropped', name)
                continue
            raw_setcookies.append(cookies[name])
        if session_cookie:
            raw_setcookies.append(session_cookie)
        # writeraw short-circuit: once used, the raw binary buffer is
        # the whole body and the text buffer is discarded; headers /
        # status / cookies still apply (Content-Type stays whatever
        # the script set, default text/html otherwise)
        raw_used, raw_body = resp.collect_raw()
        if raw_used:
            body = raw_body
        else:
            body = buf.getvalue().encode('utf-8')
        response = flask.Response(body, status=status,
                                  content_type=content_type)
        for name, value in header_list:
            response.headers[name] = value
        for value in raw_setcookies:
            response.headers.add('Set-Cookie', value)
        return response


#======================================================================
# Application construction
#======================================================================

def create_app (root=None, conf_file=None, default_root=None,
                default_source='default'):
    """Build the Flask application.

    root: root directory from the command line -r (highest priority)
    conf_file: config file path from --conf / the search chain
        (None = no config)
    default_root: final fallback for root (dev=cwd, WSGI=makoserver.py
        directory)
    Raises ConfigError on failure.
    """
    if conf_file:
        config = load_config(conf_file)
        conf_path = os.path.abspath(conf_file)
    else:
        config = dict(DEFAULT_CONFIG)
        conf_path = None
    if root:
        final_root = os.path.abspath(root)
        source = 'command line'
    elif config.get('root'):
        final_root = config['root']
        source = 'config'
    else:
        final_root = os.path.abspath(default_root or MODULE_DIR)
        source = default_source
    validate_startup(config, final_root, source)
    # make site-local .py helpers importable from templates: append
    # the document root (realpath, dedup) to sys.path TAIL so <%! %>
    # blocks can "import pkg.mod" for anything under root (py3
    # namespace packages, no __init__.py needed). Tail-appending
    # keeps stdlib / site-packages ahead of root (a root-level
    # json.py cannot shadow the stdlib). CLI mode has no root
    # concept and never reaches this path (spec decision #26).
    root_real = os.path.realpath(final_root)
    if root_real not in sys.path:
        sys.path.append(root_real)
    server = MakoServer(final_root, config, conf_path)

    app = flask.Flask('makoserver', static_folder=None)
    # request body size cap (config key max_body, default 64MB,
    # <= 0 disables the limit): a stray oversized POST would otherwise
    # be read fully into memory by get_data(cache=True); oversize
    # requests get Werkzeug's standard 413 response
    max_body = int(config.get('max_body', 67108864))
    app.config['MAX_CONTENT_LENGTH'] = max_body if max_body > 0 else None
    app.mako_server = server
    app.wsgi_app = PathInfoNormMiddleware(app.wsgi_app)

    def _dispatch (url_path):
        # view-level catch-all (decision #35): handle() branches such
        # as __build_bridge / __assemble are not individually guarded;
        # any unexpected exception must still produce the spec 9.1
        # error page AND hit the error log (Flask's default 500 only
        # goes to app.logger/stderr, unseen under WSGI hosts).
        # HTTPExceptions (413 body limit etc.) pass through to
        # Werkzeug's standard handling.
        try:
            return server.handle(url_path)
        except HTTPException:
            raise
        except Exception:
            return server.internal_error()

    def view_index ():
        return _dispatch('')

    def view_path (url_path):
        return _dispatch(url_path)

    app.add_url_rule('/', 'mako_index', view_index, methods=ALL_METHODS,
                     provide_automatic_options=False)
    app.add_url_rule('/<path:url_path>', 'mako_catchall', view_path,
                     methods=ALL_METHODS, provide_automatic_options=False)

    if config.get('access_log'):
        app.wsgi_app = AccessLogMiddleware(app.wsgi_app, config['access_log'])
    return app


#======================================================================
# CLI rendering mode
#======================================================================

def render_cli (script, args):
    """Render a single script like "php xxx.php", writing the result
    to stdout. A script name of '-' reads the template source from
    stdin (POSIX convention; PHP CLI likewise uses argv[0] = '-' for
    stdin scripts). Exits with 1 on failure."""
    if script == '-':
        # stdin mode: read raw bytes and decode like a template file
        # (utf-8-sig, BOM tolerated); includes resolve against cwd,
        # the only natural anchor when there is no script file
        base_dir = os.getcwd()
        try:
            text = sys.stdin.buffer.read().decode('utf-8-sig')
        except UnicodeDecodeError:
            sys.stderr.write('makoserver: stdin is not valid UTF-8\n')
            sys.exit(1)
        script_abs = '-'
    else:
        text = None
        script_abs = os.path.abspath(script)
        if not os.path.isfile(script_abs):
            sys.stderr.write('makoserver: no such file: %s\n' % script)
            sys.exit(1)
        base_dir = os.path.dirname(script_abs)
    store = TemplateStore(base_dir)
    buf = io.StringIO()
    echo = make_echo(buf)
    resp = RespObject(echo, cli=True)
    server = {
        'REQUEST_METHOD': 'GET',
        'QUERY_STRING': '',
        'SCRIPT_NAME': script_abs,
        'SCRIPT_FILENAME': script_abs,
        'SCRIPT_DIRNAME': base_dir,
        'PATH_INFO': '',
        'REMOTE_ADDR': '',
        'SERVER_NAME': '',
        'SERVER_PORT': '',
        'CONTENT_TYPE': '',
        'CONTENT_LENGTH': '',
        'REQUEST_TIME': int(time.time()),
        'REQUEST_TIME_FLOAT': time.time(),
        'argv': [script] + list(args),
    }
    bridge = {
        'echo': echo,
        'echoraw': resp.writeraw,
        'escape': html_escape,
        '_REQUEST': PHPDict(),
        '_BODY': b'',
        '_GET': PHPDict(),
        '_POST': PHPDict(),
        '_SERVER': server,
        '_JSON': None,
        '_COOKIE': {},
        '_SESSION': {},
        'RESP': resp,
    }
    exit_code = 0
    try:
        if text is not None:
            # stdin source is kept verbatim (no rstrip), same as file
            # loading
            tpl = Template(text=text, lookup=store,
                           uri='<stdin>', filename='-',
                           input_encoding='utf-8')
        else:
            tpl = store.get_template(os.path.basename(script_abs))
        # public Mako API only: Context + render_context; echo is
        # re-bound to ctx.write (buffer stack, decision #33)
        ctx = mako_runtime.Context(buf, **bridge)
        echo.bind(ctx.write)
        tpl.render_context(ctx)
    except SystemExit as e:
        # PHP exit()/die() semantics (decision #36): buffered output
        # is flushed, then the process exits with the given code;
        # sys.exit("message") keeps Python semantics (message to
        # stderr, exit 1)
        code = e.code
        if code is None:
            code = 0
        if not isinstance(code, int):
            sys.stderr.write('%s\n' % code)
            code = 1
        exit_code = code
    except BaseException:
        # no partial content on stdout; traceback goes to stderr
        traceback.print_exc()
        sys.exit(1)
    raw_used, raw_body = resp.collect_raw()
    if raw_used:
        # writeraw short-circuit: raw bytes only, text discarded
        sys.stdout.buffer.write(raw_body)
    else:
        sys.stdout.buffer.write(buf.getvalue().encode('utf-8'))
    sys.stdout.buffer.flush()
    if exit_code:
        sys.exit(exit_code)


#======================================================================
# CGI mode
#======================================================================

def is_cgi_environment ():
    """Detect a plain CGI invocation (Apache mod_cgi / mod_cgid,
    either cgi-bin placement or an Action mapping).

    Primary marker: GATEWAY_INTERFACE = 'CGI/1.1' (RFC 3875). Some
    servers omit it, so a secondary heuristic is applied:
    REQUEST_METHOD plus SCRIPT_FILENAME / PATH_TRANSLATED is a
    CGI-only signature, never present in interactive shells.
    """
    gateway = os.environ.get('GATEWAY_INTERFACE', '')
    if gateway.upper().startswith('CGI'):
        return True
    if os.environ.get('REQUEST_METHOD') and \
            (os.environ.get('SCRIPT_FILENAME') or
             os.environ.get('PATH_TRANSLATED')):
        return True
    return False


def run_cgi ():
    """Serve one request as a plain CGI script and exit.

    Zero-config document root falls back to the server-provided
    DOCUMENT_ROOT (not MODULE_DIR: under cgi-bin placement the
    script directory carries no site meaning); makoserver.ini /
    MAKOSERVER_CONF / ~/.config still take precedence through the
    normal search chain. Returns a process exit code.
    """
    conf_path = find_config_file()
    default_root = os.environ.get('DOCUMENT_ROOT') or MODULE_DIR
    try:
        app = create_app(conf_file=conf_path, default_root=default_root,
                         default_source='cgi document root')
    except ConfigError as e:
        sys.stderr.write('makoserver: %s\n' % e)
        return 1
    from wsgiref.handlers import CGIHandler
    CGIHandler().run(app)
    return 0


#======================================================================
# Command line entry
#======================================================================

def main (argv=None):
    parser = argparse.ArgumentParser(
        prog='makoserver.py',
        description='Mako + Flask dynamic page server (PHP-like .mako serving)')
    parser.add_argument('-r', '--root', default=None,
                        help='document root directory')
    parser.add_argument('-p', '--port', type=int, default=5000,
                        help='port to listen on (default 5000)')
    parser.add_argument('--host', default='127.0.0.1',
                        help='address to bind (default 127.0.0.1)')
    parser.add_argument('--conf', default=None,
                        help='configuration file')
    parser.add_argument('--version', action='version',
                        version='makoserver.py ' + __version__)
    parser.add_argument('script', nargs='?', default=None,
                        help='render a single script and exit (CLI mode); '
                             "use '-' to read the script from stdin")
    parser.add_argument('args', nargs=argparse.REMAINDER,
                        help='arguments passed to the script verbatim')
    opts = parser.parse_args(argv)
    if opts.script:
        render_cli(opts.script, opts.args)
        return 0
    conf_path = None
    try:
        conf_path = find_config_file(opts.conf)
        app = create_app(root=opts.root, conf_file=conf_path,
                         default_root=os.getcwd(), default_source='cwd')
    except ConfigError as e:
        sys.stderr.write('makoserver: %s\n' % e)
        return 1
    sys.stderr.write('MakoServer (%s):\n' % app.mako_server.root)
    app.run(host=opts.host, port=opts.port, threaded=True)
    return 0


#======================================================================
# Module level WSGI entry
#======================================================================

def _wsgi_bootstrap ():
    """Build the application in WSGI mode (first request)."""
    conf_path = find_config_file()
    try:
        return create_app(conf_file=conf_path, default_root=MODULE_DIR,
                          default_source='script dir')
    except ConfigError as e:
        # surface the failure through the WSGI host instead of
        # sys.exit: killing the importing process would tear down
        # co-hosted apps / test runners (decision #37)
        sys.stderr.write('makoserver: %s\n' % e)
        raise


class LazyApplication:
    """Module-level WSGI entry deferring app construction to the
    first request (decision #37, amended).

    A plain "import makoserver" stays side-effect free (no config
    search chain, no startup validation, no host key derivation),
    while "application" is still a REAL module-level binding: a PEP
    562 module __getattr__ was tried first and failed in the field --
    mod_wsgi resolves the target callable by a direct dictionary
    lookup on the script's namespace ("Target WSGI script does not
    contain WSGI application 'application'"), which never triggers
    the module attribute protocol.
    """

    def __init__ (self):
        self.app = None
        self.__lock = threading.Lock()

    def __call__ (self, environ, start_response):
        app = self.app
        if app is None:
            # double-checked locking: first concurrent requests under
            # threaded WSGI hosts must build exactly one app
            with self.__lock:
                if self.app is None:
                    self.app = _wsgi_bootstrap()
                app = self.app
        return app(environ, start_response)


application = LazyApplication()


if __name__ == '__main__':
    # CGI detection precedes argparse: mod_cgi invokes the script
    # with no arguments (argv == ['makoserver.py']); the argv guard
    # keeps CI / webhook environments with leaked CGI-ish variables
    # from hijacking an explicit "makoserver.py script.mako" run
    if is_cgi_environment() and len(sys.argv) == 1:
        sys.exit(run_cgi())
    sys.exit(main())
