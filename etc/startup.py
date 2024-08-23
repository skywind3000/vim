import sys
import site
import os

if sys.version_info[0] >= 3:
    import collections
    if 'Callable' not in collections.__dict__:
        try:
            import collections.abc
            if 'Callable' in collections.abc.__dict__:
                collections.Callable = collections.abc.Callable
        except ImportError:
            pass
    del collections

import rlcompleter

try:
    import readline
    readline.parse_and_bind('tab: complete')
    del readline
except ImportError:
    pass

if sys.platform[:3] == 'win':
    site.addsitedir('C:/Share/vim/lib')
else:
    site.addsitedir(os.path.expanduser('~/.vim/vim/lib'))

del rlcompleter, sys, os, site

try:
    import rich
    import rich.pretty
    rich.pretty.install()
    del rich
except ImportError:
    pass




