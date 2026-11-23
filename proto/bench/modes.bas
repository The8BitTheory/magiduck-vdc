10 bload"vdcbasic2h",b0,u8:sys dec("1300")
20 dim r(20),r$(20):n=100:k=0:s=20000:a=40000
30 fast:rst 1:rgo 28,16
40 t=(rgd(4)+1)*8+(rgd(5) and 31):v=rgd(7)
50 rgw 9,3:rgw 23,4:rgw 4,t/4-1:rgw 5,t and 3:rgw 6,50:rgw 7,v*2
60 rem --- text mode 80x50
70 disp 0:attr 4096
80 gosub 500:r$(k)="text: leer":gosub 900
90 t=ti:for i=1 to n:vmc s,a,80,50,80,160:next:r$(k)="text: fenster 80x50":gosub 900
100 t=ti:for i=1 to n:vmc s,a,8,8,160:next:r$(k)="text: tile 8x8":gosub 900
110 t=ti:for i=1 to n:vmc s,a,4000:next:r$(k)="text: 4000 am stueck":gosub 900
200 rem --- bitmap + attributes, 40 columns, double pixel
210 rgw 0,63:rgw 1,40:rgw 2,55:rgw 22,137:rgo 25,128+16
220 vmf 0,15,8000:disp 0:attr 8192
230 gosub 500:r$(k)="bitmap: leer":gosub 900
240 t=ti:for i=1 to n:vmc s,a,40,50,40,80:next:r$(k)="bitmap: fenster 40x50":gosub 900
250 t=ti:for i=1 to n:vmc s,a,4,8,80:next:r$(k)="bitmap: tile 4x8":gosub 900
260 t=ti:for i=1 to n:vmc s,a,2000:next:r$(k)="bitmap: 2000 am stueck":gosub 900
300 rem --- display off (r1=0 would change timing): compare with 80x25 text default
310 rst 1:rgo 28,16
320 gosub 500:r$(k)="standard 80x25: leer":gosub 900
330 t=ti:for i=1 to n:vmc s,a,4000:next:r$(k)="standard: 4000 am stueck":gosub 900
400 rst 3:print chr$(147);:for i=0 to k-1:print r$(i);tab(30);r(i):next
410 bank 15:poke dec("d7ff"),0
500 t=ti:for i=1 to n:next:return
900 r=int((ti-t)*100000/60/n)/100:r(k)=r:k=k+1:return
