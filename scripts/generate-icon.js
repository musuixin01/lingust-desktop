import fs from 'fs';
import zlib from 'zlib';
import path from 'path';

// Generate a valid 256x256 RGBA PNG icon with Apple-style rounded squircle and glass gradient
function createPngIcon(filePath) {
  const width = 256;
  const height = 256;
  const radius = 56;

  // Uncompressed scanlines: each row starts with filter byte 0
  const rowSize = 1 + width * 4;
  const buffer = Buffer.alloc(height * rowSize);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * rowSize;
    buffer[rowOffset] = 0; // Filter: None

    for (let x = 0; x < width; x++) {
      const pixelOffset = rowOffset + 1 + x * 4;

      // Squircle distance formula
      const dx = Math.abs(x - width / 2);
      const dy = Math.abs(y - height / 2);
      const halfW = width / 2 - 12;
      const halfH = height / 2 - 12;

      // Superellipse or rounded box
      const rx = halfW - radius;
      const ry = halfH - radius;
      let inside = false;

      if (dx <= rx && dy <= halfH) {
        inside = true;
      } else if (dy <= ry && dx <= halfW) {
        inside = true;
      } else {
        const cx = dx - rx;
        const cy = dy - ry;
        if (cx * cx + cy * cy <= radius * radius) {
          inside = true;
        }
      }

      if (inside) {
        // Gradient from Deep Indigo (#1e1b4b) to Wine Red (#4a0e36)
        const t = (x + y) / (width + height);
        const r = Math.round(30 * (1 - t) + 180 * t);
        const g = Math.round(27 * (1 - t) + 40 * t);
        const b = Math.round(75 * (1 - t) + 120 * t);
        const a = 245;

        // Draw an inner lighter glass border
        const isBorder = dx > halfW - 3 || dy > halfH - 3;
        if (isBorder) {
          buffer[pixelOffset] = 255;
          buffer[pixelOffset + 1] = 255;
          buffer[pixelOffset + 2] = 255;
          buffer[pixelOffset + 3] = 160;
        } else {
          buffer[pixelOffset] = r;
          buffer[pixelOffset + 1] = g;
          buffer[pixelOffset + 2] = b;
          buffer[pixelOffset + 3] = a;
        }
      } else {
        // Transparent outside
        buffer[pixelOffset] = 0;
        buffer[pixelOffset + 1] = 0;
        buffer[pixelOffset + 2] = 0;
        buffer[pixelOffset + 3] = 0;
      }
    }
  }

  const deflated = zlib.deflateSync(buffer);

  // PNG Signature
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR Chunk
  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8; // Bit depth: 8
  ihdrData[9] = 6; // Color type: RGBA (6)
  ihdrData[10] = 0; // Compression: Deflate
  ihdrData[11] = 0; // Filter: Standard
  ihdrData[12] = 0; // Interlace: None

  function makeChunk(type, data) {
    const typeBuf = Buffer.from(type, 'ascii');
    const len = data.length;
    const chunk = Buffer.alloc(4 + 4 + len + 4);
    chunk.writeUInt32BE(len, 0);
    typeBuf.copy(chunk, 4);
    data.copy(chunk, 8);

    // CRC32 calculation
    const crcTable = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) {
        if (c & 1) c = 0xedb88320 ^ (c >>> 1);
        else c = c >>> 1;
      }
      crcTable[n] = c;
    }

    let crc = 0xffffffff;
    for (let i = 4; i < 8 + len; i++) {
      crc = crcTable[(crc ^ chunk[i]) & 0xff] ^ (crc >>> 8);
    }
    crc = (crc ^ 0xffffffff) >>> 0;
    chunk.writeUInt32BE(crc, 8 + len);
    return chunk;
  }

  const ihdrChunk = makeChunk('IHDR', ihdrData);
  const idatChunk = makeChunk('IDAT', deflated);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  const pngFile = Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
  fs.writeFileSync(filePath, pngFile);
  console.log(`[Icon] Successfully generated ${filePath} (${pngFile.length} bytes)`);
}

createPngIcon(path.join(process.cwd(), 'public', 'icon.png'));
