10 bload"vdcbasic2h",b0,u8:sys dec("1300")
20 rst 1:rgo 28,16
30 t=(rgd(4)+1)*8+(rgd(5) and 31):v=rgd(7)
40 rgw 9,3:rgw 23,4:rgw 4,t/4-1:rgw 5,t and 3:rgw 6,50:rgw 7,v*2
50 vmf 0,0,4000:vmf 8192,255,4:vmf 8196,0,12
60 disp 0:attr 4096
70 for y=0 to 49:vmf 4096+y*80,(y/4) and 15,80:next
80 for x=0 to 79:vmw 4096+x,x and 15:vmw 4096+49*80+x,15-(x and 15):next
90 for i=0 to 49:vmw 4096+i*80+i+15,15:vmw 4096+i*80+64-i,0:next
100 GETKEY K$
