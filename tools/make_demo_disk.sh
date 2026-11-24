#!/bin/bash
# Build the playable demo disk proto/magiduck-demo.d81 (bitmap mode, Blitz! compiled)
# and check headless that it starts. usage: tools/make_demo_disk.sh [level]
# Compiler: as in run_proto.sh (BLITZC + NODE for the JS compiler, RUNTIME=original|improved, FASTMATH).
set -e
LEVEL=${1:-1}
ROOT=$(cd "$(dirname "$0")/.." && pwd); T=$ROOT/tools; P=$ROOT/proto; O=$P/out
RELEASE=${RELEASE:?set RELEASE to the RELEASE folder of the magiduck sources}
mkdir -p $O; W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
python3 -I $T/make_proto.py "$RELEASE" $W $LEVEL bitmap play
python3 -I $T/bastok.py $P/mdload.bas $W/mdload.prg
python3 -I $T/bastok.py $P/mdgame.bas $W/src.prg
if [ -n "$BLITZC" ]; then
    ${NODE:-node} $BLITZC/js/cli.js $W/src.prg $W/blitz --runtime ${RUNTIME:-original} --fastmath ${FASTMATH:-auto} | tail -1
else
    $T/blitzcomp.sh $W/src.prg $W/blitz >/dev/null
fi
grep -q "errors: 0" $W/blitz/screen.txt || { cat $W/blitz/screen.txt; exit 2; }
D=$P/magiduck-demo.d81
c1541 -format "magiduck vdc,md" d81 $D -write $W/mdload.prg magiduck -write $P/vdcbasic2h vdcbasic2h \
      -write $W/mdvram mdvram -write $W/mddata mddata -write $W/mdrows mdrows -write $W/blitz/c.prg mdgame >/dev/null
c1541 -attach $D -dir 2>/dev/null | grep -v "^OPENCBM\|recogn\|attached\|detached"
# smoke test: start from disk like a user would, no input; screenshot after the cycle limit
x128 -default -warp -sounddev dummy -80col -VDC64KB -drive8type 1581 -8 $D \
     -autostartprgmode 1 -autostart $D -limitcycles 60000000 -exitscreenshot $O/demo-start.png >/dev/null 2>&1 || true
python3 -I -c 'import sys; from PIL import Image; i=Image.open(sys.argv[1]); i.resize((i.width, i.height*2), Image.NEAREST).save(sys.argv[1])' $O/demo-start.png
echo "disk: $D"
