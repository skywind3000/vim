import sys
import os
import zhconv

text = sys.stdin.buffer.read().decode('utf-8', 'ignore')
output = zhconv.convert(text, 'zh-cn')

sys.stdout.buffer.write(output.encode('utf-8', 'ignore'))


