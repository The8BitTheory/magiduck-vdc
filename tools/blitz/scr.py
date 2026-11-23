import sys
d=open(sys.argv[1],'rb').read()[2:]
def ch(c):
    c&=0x7f
    if c==0: return '@'
    if 1<=c<=26: return chr(96+c)
    if 27<=c<=31: return '[\\]^_'[c-27]
    if 32<=c<=63: return chr(c)
    if 65<=c<=90: return chr(c)
    return '.'
for r in range(25): print(''.join(ch(x) for x in d[r*40:r*40+40]).rstrip())
