import sys
import html2text

text = sys.stdin.read()
sys.stdout.write(html2text.html2text(text))


