0 rem ** fi i,j,k
1 rem magiduck prototype, text or bitmap mode (see header of mddata). blitz! compatible
2 rem bank 0: frame lists 3072/3200, data 32768, row lists 40960/57344
10 dim m%(1599),yt%(639),xt%(79),ya%(50),sl%(11),sh%(11),ll%(11),lh%(11),fx%(11),fy%(11),mx%(11),my%(11)
11 dim ex%(3),ey%(3),ed%(3),ef%(3),of%(9),sq%(9),wx%(1),wy%(1)
20 fl%=3072:db=32768:nf%=300:dd%=-1
30 bank 0
31 dm%=peek(db+31):px%=peek(db)+256*peek(db+1):py%=peek(db+2)+256*peek(db+3):n%=peek(db+4)
32 for i=0 to n%-1:a=db+5+i*4:ex%(i)=peek(a)+256*peek(a+1):ey%(i)=peek(a+2)+256*peek(a+3):ed%(i)=1:next
33 xs%=peek(db+33):sw%=peek(db+34):rs%=peek(db+35)+256*peek(db+36):p0%=peek(db+37)+256*peek(db+38)
34 p1%=peek(db+39)+256*peek(db+40):rb%=peek(db+41)+256*peek(db+42):cm%=peek(db+43)+256*peek(db+44):hw%=sw%/2
35 for i=0 to 11:a=db+64+i*8:sl%(i)=peek(a):sh%(i)=peek(a+1):ll%(i)=peek(a+2):lh%(i)=peek(a+3)
36 fx%(i)=peek(a+4)-128:fy%(i)=peek(a+5)-128:mx%(i)=peek(a+6):my%(i)=peek(a+7):next
37 for i=0 to 1599:m%(i)=peek(db+512+i):next
38 for i=0 to 639:yt%(i)=int(i/8)*20:next:for i=0 to 79:xt%(i)=int(i/4):next:for i=0 to 50:ya%(i)=i*sw%:next
39 for i=0 to n%-1
40 if ey%(i)<639 and m%(yt%(ey%(i))+xt%(ex%(i)))<30 then ey%(i)=ey%(i)+1:goto 40
41 next
50 rem --- per page: 2 window copies (type 3), 5 sprites (type 12, off = type 1 count 0)
51 for j=0 to 1:a=fl%+j*128:for k=0 to 1:poke a,3:poke a+5,sw%:poke a+6,0:poke a+8,0:poke a+9,sw%:poke a+10,0:poke a+11,rs%:poke a+12,0:a=a+13:next
52 for k=0 to 4:poke a,1:for i=1 to 6:poke a+i,0:next:of%(j*5+k)=-1:sq%(j*5+k)=-1:a=a+7:next:poke a,0
53 w=p0%:if j then w=p1%
54 a=fl%+j*128:poke a+3,w and 255:poke a+4,int(w/256):wx%(j)=-1:next
55 bank 15
60 pg%=1:bp%=p1%:fb%=fl%+128:gosub 700:t0%=int(cy%/8):for k=t0% to t0%+7:rw%=k:gosub 800:next
100 t1=ti
106 u=ti
110 if dm% then gosub 900:else gosub 950
120 rem --- player
121 if jx%=0 then 130
122 pd%=-(jx%<0):w%=px%+jx%:if w%<2 or w%>77 then 130
123 if m%(yt%(py%-3)+xt%(w%+jx%*2))<30 then px%=w%:pf%=(pf%+1) and 3
130 vy%=vy%+1:if vy%>4 then vy%=4
131 if jb% and gr% then vy%=-7
132 gr%=0:w%=py%+vy%:if w%<13 then w%=13
133 if vy%<0 then if m%(yt%(w%-12)+xt%(px%))>29 then w%=py%:vy%=0
134 if vy%>=0 then if m%(yt%(w%)+xt%(px%))>29 then w%=w% and -8:vy%=0:gr%=1
135 py%=w%:if py%>632 then py%=632
139 c1=c1+ti-u:u=ti
140 rem --- enemies, every second frame
141 if fr% and 1 then 150
142 for i=0 to n%-1:w%=ex%(i)+ed%(i):if w%<2 or w%>77 then ed%(i)=-ed%(i):goto 146
143 j=xt%(w%+ed%(i)*2):q%=ey%(i)
144 if m%(yt%(q%-3)+j)>29 or m%(yt%(q%)+j)<30 then ed%(i)=-ed%(i):goto 146
145 ex%(i)=w%:ef%(i)=1-ef%(i)
146 next
150 gosub 700
159 c2=c2+ti-u:u=ti
160 rem --- tile ring buffer: refill rows that came into view
161 w%=int(cy%/8):if w%=t0% then 200
162 if w%<t0% then 166
163 q%=t0%+8:if q%<w% then q%=w%
164 for k=q% to w%+7:rw%=k:gosub 800:next:goto 169
166 q%=t0%-1:if q%>w%+7 then q%=w%+7
167 for k=w% to q%:rw%=k:gosub 800:next
169 t0%=w%
200 c3=c3+ti-u:u=ti
201 if cx%=wx%(pg%) and cy%=wy%(pg%) then 300
202 wx%(pg%)=cx%:wy%(pg%)=cy%:r0%=cy% and 63:a%=64-r0%:if a%>50 then a%=50
203 b%=50-a%:w%=rb%+r0%*rs%+cx%:poke fb%+1,w% and 255:poke fb%+2,w%/256:poke fb%+7,a%
204 w%=rb%+cx%:poke fb%+14,w% and 255:poke fb%+15,w%/256:w%=bp%+ya%(a%):poke fb%+16,w% and 255:poke fb%+17,w%/256
205 if b% then poke fb%+18,sw%:poke fb%+20,b%:else poke fb%+18,0:poke fb%+20,1
300 c4=c4+ti-u:u=ti
301 f%=pd%*4+pf%:sx%=px%*xs%+fx%(f%)-cx%:sy%=py%+fy%(f%)-cy%:k=0:gosub 600
303 for k=1 to n%:i=k-1:f%=8+ef%(i)-2*(ed%(i)<0):sx%=ex%(i)*xs%+fx%(f%)-cx%:sy%=ey%(i)+fy%(f%)-cy%:gosub 600:next
400 c5=c5+ti-u:u=ti
401 ::vcl fb%
402 c6=c6+ti-u:u=ti:bh%=bp%/256:bl%=bp% and 255
403 ::syn 20,bh%,21,bl%
404 pg%=1-pg%:if pg% then bp%=p1%:fb%=fl%+128:else bp%=p0%:fb%=fl%
405 c7=c7+ti-u:fr%=fr%+1:if fr%<nf% then 106
410 t2=ti-t1:r=int(fr%*600/t2):g=1000/60/fr%
411 ::rst 3
412 print chr$(147);"fps*10";r;"frames";fr%;"rows";rc:print"input+player";c1*g:print"enemies+cam";c2*g:print"ring buffer";c3*g
413 print"window pokes";c4*g:print"sprites";c5*g:print"vcl";c6*g:print"syn+page flip";c7*g
420 bank 15:poke dec("d7ff"),r:end
600 rem --- sprite slot k of this page: frame f% at sx%,sy% (screen bytes, rows); off when not fully visible
601 o%=pg%*5+k:a%=fb%+26+k*7:if sx%<0 or sy%<0 or sx%>mx%(f%) or sy%>my%(f%) then 620
602 if of%(o%)<>f% then poke a%,12:poke a%+1,sl%(f%):poke a%+2,sh%(f%):poke a%+5,ll%(f%):poke a%+6,lh%(f%):of%(o%)=f%
603 w%=bp%+ya%(sy%)+sx%:if w%<>sq%(o%) then poke a%+3,w% and 255:poke a%+4,w%/256:sq%(o%)=w%
604 return
620 if of%(o%)>=0 then poke a%,1:poke a%+5,0:poke a%+6,0:of%(o%)=-1:sq%(o%)=-1
621 return
700 rem --- camera (screen bytes and rows)
701 cx%=px%*xs%-hw%:if cx%<0 then cx%=0
702 if cx%>cm% then cx%=cm%
703 cy%=py%-34:if cy%<0 then cy%=0
704 if cy%>590 then cy%=590
705 return
800 rem --- tile row rw% into ring slot rw% and 7: set the slot in its list, run it
801 rc=rc+1:q=rw%:if rw%>79 then q=79
802 ra=40960+q*228:if q>52 then ra=57344+(q-53)*228
803 z%=rb%+(rw% and 7)*8*rs%:bank 0:poke ra+223,z% and 255:poke ra+224,z%/256:bank 15
804 ::vcl ra
805 return
900 rem --- demo input: walk, jump at walls and now and then
901 jx%=dd%:jb%=0:w%=px%+dd%*3:if w%<2 or w%>77 then dd%=-dd%:jx%=dd%:return
902 if m%(yt%(py%-3)+xt%(w%))>29 then jb%=1
903 if (fr% and 31)=7 then jb%=1
904 if (fr% and 127)=100 then dd%=-dd%
905 return
950 rem --- joystick 2
951 j=joy(2):jx%=0:jb%=0:if j and 128 then jb%=1
952 j=j and 15:if j=1 or j=2 or j=8 then jb%=1
953 if j>=2 and j<=4 then jx%=1
954 if j>=6 and j<=8 then jx%=-1
955 return
