10 rem magiduck prototype loader (always interpreted). mode comes from the data header
20 bload"vdcbasic2h",b0,u8:sys dec("1300")
30 if rgd(255)=0 then print"needs 64 kib vram":end
40 bload"mddata",b0,u8,p(32768):bank 0:md=peek(32800):p0=peek(32805)+256*peek(32806):p1=peek(32807)+256*peek(32808)
50 vb=peek(32813)+256*peek(32814):vl=peek(32815)+256*peek(32816):bank 15
60 fast:rst 1:rgo 28,16
70 rem 50 rows of 4 scanlines
80 t=(rgd(4)+1)*8+(rgd(5) and 31):v=rgd(7)
90 rgw 9,3:rgw 23,4:rgw 4,t/4-1:rgw 5,t and 3:rgw 6,50:rgw 7,v*2
100 if md=1 then 200
110 rem text: every char is char 0 = solid block, attribute = colour of one pixel
120 vmf 0,0,4000:vmf 8192,255,4:vmf 8196,0,12:goto 300
200 rem bitmap with attributes, 40 columns double pixel, bitmap $0f: attribute = 2 pixels
210 rgw 0,63:rgw 1,40:rgw 2,55:rgw 22,137:rgo 25,128+16
220 vmf 0,15,8000
300 disp 0:vmf p0,0,4000:vmf p1,0,4000:attr p0
310 bload"mdvram",b0,u8,p(16384):rtv 16384,vb,vl
320 bload"mdrows",b0,u8,p(40960)
330 run"mdgame",u8
