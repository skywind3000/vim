import sys
import os

sys.stdin.reconfigure(encoding = 'utf-8')
sys.stdout.reconfigure(encoding = 'utf-8')

content = [t for t in sys.stdin.read().split("\n")]

indent = 100

for line in content:
    if line.strip() == '':
        continue
    spaces = len(line) - len(line.lstrip('\t '))
    indent = min(indent, spaces)

for i in range(len(content)):
    content[i] = content[i][indent:].rstrip('\r\n\t')

extname = os.path.splitext(os.environ.get('VIM_FILENAME', ''))[-1].lower()

if extname == '.vim':
    head = '"' + ('-' * 70)
elif extname in set(('.h', '.c', '.cc', '.cpp', '.cxx', '.hh', '.hpp', '.m', '.mm')):
    head = '//' + ('-' * 69)
else:
    head = '#' + ('-' * 70)

print(head)
sys.stdout.write('\n'.join(content))
print(head)

