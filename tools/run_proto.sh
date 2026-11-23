#!/bin/bash
# Build and run the 80x50 prototype headless in x128.
# usage: tools/run_proto.sh interp|blitz [level] [text|bitmap]   (GAME=name: other .bas in proto/)
# Exit code of the program = frames per second x 10 (debug cartridge).
# Screenshot of the last frame: proto/out/<mode>.png
set -e
MODE=${1:-blitz}; LEVEL=${2:-1}; GFX=${3:-bitmap}
ROOT=$(cd "$(dirname "$0")/.." && pwd); T=$ROOT/tools; P=$ROOT/proto; O=$P/out
RELEASE=${RELEASE:?set RELEASE to the RELEASE folder of the magiduck sources}
mkdir -p $O; W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
python3 -I $T/make_proto.py "$RELEASE" $W $LEVEL $GFX >/dev/null
python3 -I $T/bastok.py $P/mdload.bas $W/mdload.prg
if [ $MODE = interp ]; then
    sed 's/nf%=300/nf%=40/' $P/${GAME:-mdgame}.bas > $W/mdgame.bas
    python3 -I $T/bastok.py $W/mdgame.bas $W/mdgame
else
    python3 -I $T/bastok.py $P/${GAME:-mdgame}.bas $W/src.prg
    $T/blitzcomp.sh $W/src.prg $W/blitz >/dev/null
    grep -q "errors: 0" $W/blitz/screen.txt || { cat $W/blitz/screen.txt; exit 2; }
    cp $W/blitz/c.prg $W/mdgame; cp $W/blitz/screen.txt $O/blitz-compile.txt
fi
c1541 -format "md,01" d81 $W/t.d81 -write $W/mdload.prg mdload -write $P/vdcbasic2h vdcbasic2h -write $W/mdvram mdvram \
      -write $W/mddata mddata -write $W/mdrows mdrows -write $W/mdgame mdgame >/dev/null
set +e
x128 -default -warp -sounddev dummy -debugcart -80col -VDC64KB -drive8type 1581 -8 $W/t.d81 \
     -autostartprgmode 1 -autostart $W/t.d81 -limitcycles ${LIMIT:-400000000} \
     -exitscreenshot $O/$MODE-$GFX.png > $O/$MODE-$GFX.log 2>&1
rc=$?
python3 -I -c 'import sys; from PIL import Image; i=Image.open(sys.argv[1]); i.resize((i.width, i.height*2), Image.NEAREST).save(sys.argv[1])' $O/$MODE-$GFX.png
echo "$MODE $GFX: exit $rc -> $(python3 -c "print($rc/10)") fps"; tail -2 $O/$MODE-$GFX.log
