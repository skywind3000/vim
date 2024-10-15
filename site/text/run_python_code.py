import sys
import os

encoding = 'utf-8'

if 'VIM_ENCODING' in os.environ:
    t = os.environ['VIM_ENCODING'].strip()
    if t:
        encoding = t

sys.stdin.reconfigure(encoding = encoding)
sys.stdout.reconfigure(encoding = encoding)

content = sys.stdin.read()
print(content)

print("--------------->\n")

try:
    exec(content)
except Exception:
    import traceback
    traceback.print_exc(file = sys.stdout)



