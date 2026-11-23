#!/bin/bash
# Compile a tokenized BASIC 7 PRG with the original Blitz! 128 headless in x128.
# Adapted from oracle/compile.sh of github.com/the8bittheory/blitz-compiler (VICE in PATH).
# usage: blitzcomp.sh <in.prg> <outdir>   -> outdir/c.prg, z.prg, screen.txt
set -e
HERE=$(cd "$(dirname "$0")/blitz" && pwd); BLITZ=${BLITZ:-$HERE/blitz!.128.prg}
IN=$1; OUT=$2; MENU=${3:-1}
mkdir -p $OUT; W=$(mktemp -d)
c1541 -format "work,01" d81 $W/w.d81 -write "$BLITZ" "blitz!.128" -write "$IN" "prog" >/dev/null 2>&1
cat > $W/st.mon <<EOM
break exec 2221
command 1 "enable 2;x"
break exec ff17
ignore 2 ${FRAMES:-4000}
disable 2
command 2 "bank ram;save \"$W/scr.bin\" 0 0400 07e7;quit"
x
EOM
timeout ${TMO:-300} x128 -default -warp -sounddev dummy -drive8type 1581 -8 $W/w.d81 -moncommands $W/st.mon \
  -limitcycles ${CYCLES:-900000000} -keybuf "load\"blitz!.128\",8\nrun\n${MENU}prog\n" > $W/vice.log 2>&1 || true
python3 -I $HERE/scr.py $W/scr.bin > $OUT/screen.txt || true
for f in c z; do c1541 -attach $W/w.d81 -read "$f/prog" $OUT/$f.prg >/dev/null 2>&1 || rm -f $OUT/$f.prg; done
rm -rf $W
