#!/usr/bin/env python
from argparse import ArgumentParser 

parser=ArgumentParser(description='String reversal')
parser.add_argument('quote',type=str,nargs='?',default="What is your name?")
args=parser.parse_args()

#quote_rev = list(args.quote)
#print quote_rev.reverse()
#print ''.join(quote_rev.reverse())
#print ''.join()

quote_rev = []
for i in args.quote:
    quote_rev.insert(0,i)
quote_rev=''.join(quote_rev)
print quote_rev
