"""Read the packed MagiDuck (DOS) data files: levels, tilesets, sprites.

Formats (from libElf.asm / LIBELF19.BAS of github.com/bluepandion/magiduck):
- Pixels: CGA attribute byte with character 222 (right half block):
  high nibble = left pixel, low nibble = right pixel, colours CGA IRGB.
- LEVELS.CLP: word table of 1-based file offsets (level*2). Per level:
  playerX, playerY, tileset (words), spriteset (8 chars), coins, keys (words),
  RLE length (word), RLE map (byte >127: run of (b&127) times next byte),
  20x80 tiles; then spawner count (byte) and per spawner: index byte + 4 words.
- TILES.CTP: word table of 1-based offsets (set*2), per set: length word,
  RLE data (byte with high nibble $B: run of (low nibble+2) times next byte),
  unpacks to 1920 bytes = 60 tiles of 4 bytes x 8 rows. Tile index > 29 is solid.
- *.CSP: BSAVE file (7 byte header). Word: colour data length, colour bytes,
  word: mask length, mask bits (bit 2k -> left nibble, 2k+1 -> right nibble).
  Unpacked bank: pairs (colour, mask), sheet 40 pairs = 80 px wide.
- *.CSD: records: anim number (word, -1 = end), offset normal, offset flipped,
  w (bytes = 2 px), h (rows), x, y, jump (words). Offsets are bank byte offsets.
"""
import struct

def w(b, o):
    return struct.unpack_from('<H', b, o)[0]

def sw(b, o):
    return struct.unpack_from('<h', b, o)[0]

def cga2vdc(c):
    """CGA IRGB index -> VDC RGBI index."""
    i, r, g, b = (c >> 3) & 1, (c >> 2) & 1, (c >> 1) & 1, c & 1
    return (r << 3) | (g << 2) | (b << 1) | i

CGA_RGB = [(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),
           (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]

def load_level(clp, n):
    o = w(clp, n * 2) - 1
    lv = {'px': sw(clp, o), 'py': sw(clp, o + 2), 'tileset': w(clp, o + 4),
          'spriteset': clp[o + 6:o + 14].decode('latin1').rstrip('\0 '),
          'coins': w(clp, o + 14), 'keys': w(clp, o + 16)}
    o += 18
    ln = w(clp, o); o += 2
    rle = clp[o:o + ln]; o += ln
    m = bytearray()
    i = 0
    while len(m) < 1600 and i < len(rle):
        b = rle[i]; i += 1
        if b > 127:
            m += bytes([rle[i]]) * (b & 127); i += 1
        else:
            m.append(b)
    lv['map'] = bytes(m[:1600]).ljust(1600, b'\0')
    cnt = clp[o]; o += 1
    sp = []
    for _ in range(cnt):
        idx = clp[o]; x, y, obj, fl = struct.unpack_from('<hhhh', clp, o + 1)
        sp.append((idx, x, y, obj, fl)); o += 9
    lv['spawners'] = sp
    return lv

def load_tileset(ctp, n):
    o = w(ctp, n * 2) - 1
    ln = w(ctp, o); o += 2
    rle = ctp[o:o + ln]
    t = bytearray(); i = 0
    while len(t) < 1920 and i < len(rle):
        b = rle[i]; i += 1
        if b & 0xF0 == 0xB0:
            t += bytes([rle[i]]) * ((b & 15) + 2); i += 1
        else:
            t.append(b)
    return bytes(t[:1920]).ljust(1920, b'\0')

def tile_pixels(ts, t):
    """8x8 list of CGA colours of tile t."""
    rows = []
    for y in range(8):
        r = []
        for x in range(4):
            a = ts[t * 32 + y * 4 + x]
            r += [a >> 4, a & 15]
        rows.append(r)
    return rows

def load_sprite_bank(csp):
    d = csp[7:]                       # BSAVE header
    cl = w(d, 0); col = d[2:2 + cl]
    o = 2 + cl; ml = w(d, o); mask = d[o + 2:o + 2 + ml]
    bank = bytearray(cl * 2)
    bank[0::2] = col
    mb = bytearray()
    for m in mask:
        for k in range(0, 8, 2):
            v = (0x0F if m & (1 << k) else 0) | (0xF0 if m & (1 << (k + 1)) else 0)
            mb.append(v)
    mb = mb[:cl]
    bank[1:1 + 2 * len(mb):2] = mb
    return bytes(bank)

def load_anims(csd):
    an = {}; o = 0
    while o + 2 <= len(csd):
        n = sw(csd, o); o += 2
        if n < 0:
            break
        off0, off1, ww, h, x, y, j = struct.unpack_from('<HHhhhhh', csd, o); o += 14
        an[n] = dict(off=(off0, off1), w=ww, h=h, x=x, y=y, jump=j)
    return an

def sprite_pixels(bank, off, wb, h, stride=80):
    """rows of pixels: CGA colour or None (transparent)."""
    rows = []
    for y in range(h):
        r = []
        for x in range(wb):
            p = off + y * stride + x * 2
            if p + 1 >= len(bank):
                r += [None, None]; continue
            c, m = bank[p], bank[p + 1]
            r.append(None if m & 0xF0 else c >> 4)
            r.append(None if m & 0x0F else c & 15)
        rows.append(r)
    return rows
