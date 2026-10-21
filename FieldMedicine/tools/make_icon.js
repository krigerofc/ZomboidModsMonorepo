// Generates the neutral 64x64 placeholder icon (gray square, white cross). Run once: node tools/make_icon.js <out.png>
const fs = require('fs'); const zlib = require('zlib');
const W = 64, H = 64; const raw = Buffer.alloc((W * 3 + 1) * H);
for (let y = 0; y < H; y++) {
  raw[y * (W * 3 + 1)] = 0;
  for (let x = 0; x < W; x++) {
    const cross = (x >= 26 && x < 38 && y >= 12 && y < 52) || (y >= 26 && y < 38 && x >= 12 && x < 52);
    const border = x < 2 || y < 2 || x >= W - 2 || y >= H - 2;
    const v = cross ? [235, 235, 235] : border ? [70, 70, 70] : [110, 110, 110];
    v.forEach((c, i) => { raw[y * (W * 3 + 1) + 1 + x * 3 + i] = c; });
  }
}
const crcTable = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = (b) => { let c = 0xffffffff; for (const x of b) c = crcTable[(c ^ x) & 0xff] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const len = Buffer.alloc(4); len.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([len, td, c]); };
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 2;
fs.writeFileSync(process.argv[2], Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
