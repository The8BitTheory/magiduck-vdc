10 bload"vdcbasic2h",b0,u8:sys dec("1300")
20 rgo 28,16:dim a(7),m%(9,9):n=200:s=20000:a=40000:k=0:dim r(40),r$(40):c=5:d=1:g=1:vy=0:y=0:x=40
25 for p=0 to 1:if p=0 then fast:r$(k)="fast":k=k+1:else slow:r$(k)="slow":k=k+1
30 t=ti:for i=1 to n:next:b=ti-t
40 t=ti:for i=1 to n:x=x+d:next:gosub 900:r$(k)="x=x+d":r(k)=r:k=k+1
45 t=ti:for i=1 to n:if x>s then x=0:next:else next
46 gosub 900:r$(k)="if x>s then (false)":r(k)=r:k=k+1
50 t=ti:for i=1 to n:a(i and 7)=a(i and 7)+1:next:gosub 900:r$(k)="a(i and 7)=a(..)+1":r(k)=r:k=k+1
60 t=ti:for i=1 to n:vmw a,c:next:gosub 900:r$(k)="vmw a,c":r(k)=r:k=k+1
65 t=ti:for i=1 to n:vmw a+x*2+80,c:next:gosub 900:r$(k)="vmw a+x*2+80,c":r(k)=r:k=k+1
70 t=ti:for i=1 to n:e=vmd(a):next:gosub 900:r$(k)="e=vmd(a)":r(k)=r:k=k+1
80 t=ti:for i=1 to n:vmc s,a,4000:next:gosub 900:r$(k)="vmc s,a,4000":r(k)=r:k=k+1
85 t=ti:for i=1 to n:vmc s,a,80,50,80,160:next:gosub 900:r$(k)="vmc s,a,80,50,80,160":r(k)=r:k=k+1
90 t=ti:for i=1 to n:vmc s,a,8,8,80:next:gosub 900:r$(k)="vmc s,a,8,8,80 (tile)":r(k)=r:k=k+1
95 t=ti:for i=1 to n:vmc s,a+x,8,8,80:next:gosub 900:r$(k)="vmc s,a+x,8,8,80":r(k)=r:k=k+1
100 t=ti:for i=1 to n:vy=vy+g:if vy>8 then vy=8
101 y=y+vy:if m%(x/8 and 7,y/8 and 7) then y=y-vy:vy=0
102 if y>60 then y=0
103 next:gosub 900:r$(k)="physik (3 zeilen)":r(k)=r:k=k+1
110 next p
115 rst 3:print chr$(147);:for i=0 to k-1:print r$(i);r(i):next
120 GETKEY K$
900 r=int((ti-t-b)*100000/60/n)/100:return
