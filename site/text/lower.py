import sys
import os

if os.environ.get('VIM_ENCODING'):
    encoding = os.environ['VIM_ENCODING']
    sys.stdin.reconfigure(encoding = encoding)
    sys.stdout.reconfigure(encoding = encoding)

for line in sys.stdin:
    sys.stdout.write(line.lower())

