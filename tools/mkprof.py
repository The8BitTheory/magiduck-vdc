"""Make proto/mdprof.bas from proto/mdgame.bas: TI time per section, printed at the end."""
import sys
src = open(sys.argv[1]).read().splitlines(); out = []
rep = {'200': '200 c3=c3+ti-u:u=ti', '300': '300 c4=c4+ti-u:u=ti', '400': '400 c5=c5+ti-u:u=ti'}
for l in src:
    n = l.split(' ', 1)[0]
    if n in rep: out.append(rep[n]); continue
    if n == '402': l = '402 c6=c6+ti-u:u=ti:' + l.split(' ', 1)[1]
    if n == '405': l = '405 c7=c7+ti-u:fr%=fr%+1:if fr%<nf% then 106'
    if n == '801': l = '801 rc=rc+1:' + l.split(' ', 1)[1]
    if n == '410':
        out += ['410 t2=ti-t1:r=int(fr%*600/t2):g=1000/60/fr%', '411 ::rst 3',
                '412 print chr$(147);"fps*10";r;"frames";fr%;"rows";rc:print"input+player";c1*g:print"enemies+cam";c2*g:print"ring buffer";c3*g',
                '413 print"window pokes";c4*g:print"sprites";c5*g:print"vcl";c6*g:print"syn+page flip";c7*g']
        continue
    out.append(l)
    if n == '100': out.append('106 u=ti')
    if n == '135': out.append('139 c1=c1+ti-u:u=ti')
    if n == '150': out.append('159 c2=c2+ti-u:u=ti')
open(sys.argv[2], 'w').write('\n'.join(out) + '\n')
