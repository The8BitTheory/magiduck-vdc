"""Build the data files of the prototype, for the 80x50 text mode or the bitmap mode.

usage: python3 -I make_proto.py <magiduck RELEASE dir> <out dir> [level] [text|bitmap] [demo|play]

Modes (both show 80x50 game pixels, 4 scanlines per row):
  text    80 columns, every char is char 0 (solid block), one attribute byte = 1 pixel
  bitmap  40 columns with double pixels, bitmap filled with $0F,
          one attribute byte = 2 pixels (high nibble left, low nibble right),
          the same layout as the CGA original

Output files (PRG):
  mddata  bank 0 at $8000: header, frame table, level map, VMS lists
  mdvram  loaded to bank 0 at $4000, copied to VRAM at VBASE: tiles, sprite pixel data
  mdrows  bank 0 at $A000: one VCL list per level tile row (228 bytes each),
          rows 0-52 from $A000, rows 53-79 from $E000 (VCL lists must avoid $D000-$DFFF)

mddata header ($8000):
  $00 player x (word, bytes = 2 px), y (word, rows)   $04 enemies n, then n x (x word, y word)
  $1F 1 = demo (automatic input, ends after 300 frames with fps x 10 as exit code), 0 = play
  $20 mode (0 text, 1 bitmap), xs (screen bytes per game x unit), sw (screen bytes per row)
  $23 ring stride (word), $25 page 0, $27 page 1, $29 ring base, $2B max camera x (words)
  $2D VBASE, $2F length of mdvram (words)
  $40 frame table, 8 bytes per frame: source, list (words), dx (+128, screen bytes), dy (+128, rows),
      max sx, max sy (screen position at which the sprite still fits)
  $200 level map 20 x 80, $840 VMS lists
"""
import os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mdgfx import *

BASE = 0x8000
ROWS0, ROWS1, ROWSPLIT, ROWLEN = 0xA000, 0xE000, 53, 228
AUX = 4480             # SPENEMY0 bank lies behind the 4480 bytes of SPRITES0

MODES = {
    # sw: bytes per screen row, ppb: pixels per byte, VRAM memory map
    'text':   dict(sw=80, ppb=1, page0=0x1000, page1=0x2800, ring=0x3800, stg=0x6000, vbase=0x6800),
    'bitmap': dict(sw=40, ppb=2, page0=0x2000, page1=0x2800, ring=0x3000, stg=0x4400, vbase=0x4800),
}

def compose(parts):
    """parts: list of (pixel rows, x px, y). Later parts on top. -> rows, x0, y0"""
    x0 = min(x for _, x, _ in parts); y0 = min(y for _, _, y in parts)
    x1 = max(x + len(p[0]) for p, x, _ in parts); y1 = max(y + len(p) for p, _, y in parts)
    g = [[None] * (x1 - x0) for _ in range(y1 - y0)]
    for p, x, y in parts:
        for yy, row in enumerate(p):
            for xx, c in enumerate(row):
                if c is not None:
                    g[y - y0 + yy][x - x0 + xx] = c
    return g, x0, y0

def main():
    rel, out = sys.argv[1], sys.argv[2]
    lvn = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    mode = sys.argv[4] if len(sys.argv) > 4 else 'bitmap'
    demo = (sys.argv[5] if len(sys.argv) > 5 else 'demo') == 'demo'
    M = MODES[mode]; sw, ppb = M['sw'], M['ppb']
    rs = 160 // ppb                      # ring stride: full level width
    rd = lambda f: open(os.path.join(rel, f), 'rb').read()
    lv = load_level(rd('LEVELS.CLP'), lvn)
    ts = load_tileset(rd('TILES.CTP'), lv['tileset'])
    banks = {s: load_sprite_bank(rd(s + '.CSP')) for s in ('SPRITES0', 'SPENEMY0')}
    anims = {s: load_anims(rd(s + '.CSD')) for s in ('SPRITES0', 'SPENEMY0')}

    def anim(sheet, a, flip):
        an = anims[sheet][a]
        off = an['off'][flip] - (AUX if sheet == 'SPENEMY0' else 0)
        return sprite_pixels(banks[sheet], off, an['w'], an['h']), an['x'] * 2, an['y']

    # frames 0-7: duck = body (walk 1,2,3,5) with the head (anim 11) on top, 4 per direction
    # frames 8-11: enemy anims 70,71, then flipped
    frames = []
    for flip in (0, 1):
        for a in (1, 2, 3, 5):
            frames.append(compose([anim('SPRITES0', a, flip), anim('SPRITES0', 11, flip)]))
    for flip in (0, 1):
        for a in (70, 71):
            frames.append(compose([anim('SPENEMY0', a, flip)]))

    vt = M['vbase']                      # tiles first
    vram = bytearray()
    for t in range(60):
        for row in tile_pixels(ts, t):
            row = [cga2vdc(c) for c in row]
            vram += bytes(row) if ppb == 1 else bytes((row[i] << 4) | row[i + 1] for i in range(0, 8, 2))
    tsize = 64 // ppb

    data = bytearray(0x840)
    struct.pack_into('<HH', data, 0, lv['px'], lv['py'])
    en = [s for s in lv['spawners'] if s[3] in (1, 2)][:4]
    data[4] = len(en)
    for i, s in enumerate(en):
        struct.pack_into('<HH', data, 5 + i * 4, s[1], s[2])
    data[0x200:0x200 + 1600] = lv['map']

    for i, (px, x0, y0) in enumerate(frames):
        if ppb == 2 and x0 % 2:          # keep byte alignment: pad one transparent pixel left
            px = [[None] + r for r in px]; x0 -= 1
        if ppb == 2 and len(px[0]) % 2:
            px = [r + [None] for r in px]
        used = {cga2vdc(c) for r in px for c in r if c is not None}
        alpha = next(c for c in range(16) if c not in used)
        src = vt + len(vram); lst = BASE + len(data)
        ent = bytearray(); n = 0
        for y, row in enumerate(px):
            if ppb == 1:
                cells = [(cga2vdc(c) if c is not None else None, c is not None) for c in row]
                full = [c is not None for c in row]
                vals = [cga2vdc(c) if c is not None else 0 for c in row]
                kinds = ['f' if f else None for f in full]
            else:
                kinds, vals = [], []
                for b in range(0, len(row), 2):
                    l, r = row[b], row[b + 1]
                    if l is not None and r is not None:
                        kinds.append('f'); vals.append((cga2vdc(l) << 4) | cga2vdc(r))
                    elif l is None and r is None:
                        kinds.append(None); vals.append(0)
                    else:   # one pixel transparent: type 8, transparent nibble = alpha
                        kinds.append('m')
                        vals.append(((cga2vdc(l) if l is not None else alpha) << 4) |
                                    (cga2vdc(r) if r is not None else alpha))
            x = 0
            while x < len(kinds):
                if kinds[x] is None:
                    x += 1
                elif kinds[x] == 'm':
                    ent += bytes([8]) + struct.pack('<H', y * sw + x); vram.append(vals[x]); n += 1; x += 1
                else:
                    xs = x
                    while x < len(kinds) and kinds[x] == 'f':
                        vram.append(vals[x]); x += 1
                    ent += bytes([1]) + struct.pack('<HB', y * sw + xs, x - xs); n += 1
        data += bytes([alpha]) + struct.pack('<H', n) + ent
        wb, h = len(px[0]) // ppb, len(px)
        struct.pack_into('<HHBBBB', data, 0x40 + i * 8, src, lst,
                         (x0 // ppb + 128) & 255, (y0 + 128) & 255, sw - wb, 50 - h)

    data[0x1F] = 1 if demo else 0
    data[0x20:0x23] = bytes([1 if mode == 'bitmap' else 0, 2 // ppb, sw])
    struct.pack_into('<HHHHHHH', data, 0x23, rs, M['page0'], M['page1'], M['ring'], rs - sw, vt, len(vram))
    assert BASE + len(data) < ROWS0, 'mddata too large'
    assert vt + len(vram) < 0x8000 and len(vram) < 0x4000

    # row lists in bank 0 RAM: 20 tile blits into the staging row, then staging -> ring slot
    # (the program pokes the slot address at offset 223 and runs VCL on the list)
    rows = bytearray(ROWS1 + (80 - ROWSPLIT) * ROWLEN - ROWS0)
    for t in range(80):
        e = bytearray()
        for i in range(20):
            e += bytes([2]) + struct.pack('<HHHHH', vt + lv['map'][t * 20 + i] * tsize,
                                          M['stg'] + i * (8 // ppb), 8 // ppb, 8, rs)
        e += bytes([1]) + struct.pack('<HHH', M['stg'], 0, 8 * rs) + bytes([0])
        assert len(e) == ROWLEN
        a = (ROWS0 + t * ROWLEN) if t < ROWSPLIT else (ROWS1 + (t - ROWSPLIT) * ROWLEN)
        rows[a - ROWS0:a - ROWS0 + ROWLEN] = e
    assert ROWS0 + ROWSPLIT * ROWLEN <= 0xD000

    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, 'mddata'), 'wb').write(struct.pack('<H', BASE) + data)
    open(os.path.join(out, 'mdvram'), 'wb').write(struct.pack('<H', 0x4000) + vram)
    open(os.path.join(out, 'mdrows'), 'wb').write(struct.pack('<H', ROWS0) + rows)
    print(f'{mode}: level {lvn}, mdvram {len(vram)} bytes at VRAM ${vt:04X}, mddata {len(data)} bytes')

if __name__ == '__main__':
    main()
