from __future__ import print_function, unicode_literals
from bs4 import BeautifulSoup as bs
import sys

# This is one way to load a file into a variable:
# lh = open("/Users/mruten/Projects/jacksontriggs/app/assets/javascripts/jt/contactUsComments.html").read()

# But, we'll read from standard input, so we can pipe output to it
# i.e. run with cat filename.html | this_file.py
data = sys.stdin.readlines()
# print "Counted", len(data), "lines."
data = "".join(data)
# die
#sys.exit()

# root = data.tostring(sliderRoot) #convert the generated HTML to a string
try:
    soup = bs(data, 'lxml')           # make BeautifulSoup
except:
    soup = bs(data, 'html.parser')    # make BeautifulSoup

prettyHTML = soup.prettify()          # prettify the html

print(prettyHTML)


