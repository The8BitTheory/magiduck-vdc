1 trap 990
10 bload"vdcbasic2h",b0,u8:sys dec("1300")
20 ::rgo 28,16
30 dim a(7),m%(9,9),r(40),r$(40)
40 n=200:s=20000:a=40000:c=5:d=1:g=1:vy=0:y=0:x=40:k=0:d%=1:x%=40:y%=0:v%=0:g%=1:l=dec("c000")
50 bank 0:p=l:for j=0 to 9:poke p,2:p=p+1:w=s:gosub 800:w=a+j*8:gosub 800:w=8:gosub 800:w=8:gosub 800:w=80:gosub 800:next:poke p,0:bank 15
60 fast
70 t=ti:for i=1 to n:next:b=ti-t
80 t=ti:for i=1 to n:x=x+d:next:r$(k)="x=x+d":gosub 900
90 t=ti:for i=1 to n:x%=x%+d%:next:r$(k)="x%=x%+d%":gosub 900:x%=40
100 t=ti:for i=1 to n:if x>s then x=0
101 next:r$(k)="if x>s then":gosub 900
110 t=ti:for i=1 to n:a(i and 7)=a(i and 7)+1:next:r$(k)="a(i and 7)=a(..)+1":gosub 900
120 bank 0:t=ti:for i=1 to n:poke l+3,x%:next:r$(k)="poke l+3,x%":gosub 900:bank 15
130 t=ti:for i=1 to n
131 ::vmw a,c
132 next:r$(k)="::vmw a,c":gosub 900
140 t=ti:for i=1 to n
141 ::vmw a+x*2+80,c
142 next:r$(k)="::vmw a+x*2+80,c":gosub 900
150 t=ti:for i=1 to n
151 ::vmc s,a,8,8,80
152 next:r$(k)="::vmc s,a,8,8,80 (tile)":gosub 900
160 t=ti:for i=1 to n
161 ::vmc s,a,80,50,80,160
162 next:r$(k)="::vmc 80x50 fenster":gosub 900
170 t=ti:for i=1 to n
171 ::vcl l
172 next:r$(k)="::vcl (10 tiles)":gosub 900
180 t=ti:for i=1 to n:vy=vy+g:if vy>8 then vy=8
181 y=y+vy:if m%(x/8 and 7,y/8 and 7) then y=y-vy:vy=0
182 if y>60 then y=0
183 next:r$(k)="physik float (3 z.)":gosub 900
190 t=ti:for i=1 to n:v%=v%+g%:if v%>8 then v%=8
191 y%=y%+v%:if m%(x%/8 and 7,y%/8 and 7) then y%=y%-v%:v%=0
192 if y%>60 then y%=0
193 next:r$(k)="physik int% (3 z.)":gosub 900
500 ::rst 3
510 print chr$(147);:for i=0 to k-1:print r$(i);tab(28);r(i):next
520 bank 15:poke dec("d7ff"),0
800 h=int(w/256):poke p,w-h*256:poke p+1,h:p=p+2:return
900 r=int((ti-t-b)*100000/60/n)/100:r(k)=r:k=k+1:return
990 rst 3:print chr$(147);"error";er;"line";el:bank 15:poke dec("d7ff"),99
