#!/usr/bin/env python3
import struct
import zlib
import os
import math

def generate_png(width, height, get_pixel_func):
    """
    Generates a valid PNG image byte array from a pixel function get_pixel_func(x, y) -> (r, g, b, a).
    """
    # PNG signature
    png_data = bytearray(b'\x89PNG\r\n\x1a\n')

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0) # 8-bit RGBA
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    png_data.extend(struct.pack('>I', len(ihdr_data)))
    png_data.extend(b'IHDR')
    png_data.extend(ihdr_data)
    png_data.extend(struct.pack('>I', ihdr_crc))

    # IDAT chunk (raw RGBA data with 0 filter byte per scanline)
    raw_scanlines = bytearray()
    for y in range(height):
        raw_scanlines.append(0) # None filter
        for x in range(width):
            r, g, b, a = get_pixel_func(x, y)
            raw_scanlines.extend([
                max(0, min(255, int(r))),
                max(0, min(255, int(g))),
                max(0, min(255, int(b))),
                max(0, min(255, int(a)))
            ])

    compressed_idat = zlib.compress(raw_scanlines, level=9)
    idat_crc = zlib.crc32(b'IDAT' + compressed_idat)
    png_data.extend(struct.pack('>I', len(compressed_idat)))
    png_data.extend(b'IDAT')
    png_data.extend(compressed_idat)
    png_data.extend(struct.pack('>I', idat_crc))

    # IEND chunk
    iend_crc = zlib.crc32(b'IEND')
    png_data.extend(struct.pack('>I', 0))
    png_data.extend(b'IEND')
    png_data.extend(struct.pack('>I', iend_crc))

    return bytes(png_data)

def render_ibuild_icon(size, maskable=False):
    """
    Renders the IBUILD logo icon with supersampling antialiasing.
    """
    # We will supersample 4x4 per pixel for smooth crisp edges
    scale = 4
    sw = size * scale
    sh = size * scale

    # Geometry relative to sw, sh
    pad = (sw * 0.10) if maskable else 0.0
    area = sw - pad * 2.0
    cx_offset = pad
    cy_offset = pad

    radius = area * 0.22

    # Columns coordinates
    w = area
    h = area
    col_w = w * 0.18
    gap = w * 0.04

    lx1 = cx_offset + w * 0.20
    lx2 = lx1 + col_w
    ly1 = cy_offset + h * 0.46
    ly2 = cy_offset + h * 0.82

    cx1 = lx1 + col_w + gap
    cx2 = cx1 + col_w
    cy1 = cy_offset + h * 0.22
    cy2 = cy_offset + h * 0.82

    rx1 = cx1 + col_w + gap
    rx2 = rx1 + col_w
    ry1 = cy_offset + h * 0.36
    ry2 = cy_offset + h * 0.82

    # Emerald chevron
    chev_cx = (cx1 + cx2) / 2.0
    chev_top = cy1 - h * 0.08
    chev_base = cy1 + h * 0.02
    chev_hw = col_w * 0.65

    # Foundation base
    base_y1 = cy_offset + h * 0.84
    base_y2 = cy_offset + h * 0.88
    base_x1 = cx_offset + w * 0.16
    base_x2 = cx_offset + w * 0.84

    def in_rounded_rect(px, py, rx1, ry1, rx2, ry2, r):
        if px < rx1 or px > rx2 or py < ry1 or py > ry2:
            return False
        # corners check
        if px < rx1 + r and py < ry1 + r:
            return (px - (rx1 + r))**2 + (py - (ry1 + r))**2 <= r**2
        if px > rx2 - r and py < ry1 + r:
            return (px - (rx2 - r))**2 + (py - (ry1 + r))**2 <= r**2
        if px < rx1 + r and py > ry2 - r:
            return (px - (rx1 + r))**2 + (py - (ry2 - r))**2 <= r**2
        if px > rx2 - r and py > ry2 - r:
            return (px - (rx2 - r))**2 + (py - (ry2 - r))**2 <= r**2
        return True

    def in_triangle(px, py, x1, y1, x2, y2, x3, y3):
        # Barycentric coordinate check
        denom = (y2 - y3)*(x1 - x3) + (x3 - x2)*(y1 - y3)
        if abs(denom) < 1e-6:
            return False
        a = ((y2 - y3)*(px - x3) + (x3 - x2)*(py - y3)) / denom
        b = ((y3 - y1)*(px - x3) + (x1 - x3)*(py - y3)) / denom
        c = 1.0 - a - b
        return a >= 0 and b >= 0 and c >= 0

    # High res buffer
    hires = []
    for y in range(sh):
        row = []
        t = y / max(1, sh - 1)
        # Background gradient: #1E40AF to #0D2563
        bg_r = int(0x1E * (1 - t) + 0x0D * t)
        bg_g = int(0x40 * (1 - t) + 0x25 * t)
        bg_b = int(0xAF * (1 - t) + 0x63 * t)

        for x in range(sw):
            # Check rounded square bg if not maskable or inside maskable bounds
            if not maskable:
                bg_inside = in_rounded_rect(x, y, cx_offset, cy_offset, cx_offset + area, cy_offset + area, radius)
            else:
                bg_inside = True

            if not bg_inside:
                row.append((0, 0, 0, 0))
                continue

            # Default background color
            r, g, b, a = bg_r, bg_g, bg_b, 255

            # Base line
            if base_x1 <= x <= base_x2 and base_y1 <= y <= base_y2:
                r, g, b, a = 255, 255, 255, 255

            # Left column
            elif in_rounded_rect(x, y, lx1, ly1, lx2, ly2, col_w * 0.15):
                r, g, b, a = 225, 235, 255, 255

            # Right column
            elif in_rounded_rect(x, y, rx1, ry1, rx2, ry2, col_w * 0.15):
                r, g, b, a = 225, 235, 255, 255

            # Center column
            elif in_rounded_rect(x, y, cx1, cy1, cx2, cy2, col_w * 0.15):
                r, g, b, a = 255, 255, 255, 255

            # Emerald Chevron
            elif in_triangle(x, y, chev_cx, chev_top, chev_cx + chev_hw, chev_base, chev_cx - chev_hw, chev_base):
                r, g, b, a = 5, 150, 105, 255

            row.append((r, g, b, a))
        hires.append(row)

    # Downsample using box filter
    def get_downsampled_pixel(out_x, out_y):
        acc_r, acc_g, acc_b, acc_a = 0, 0, 0, 0
        samples = scale * scale
        for sy in range(scale):
            for sx in range(scale):
                pr, pg, pb, pa = hires[out_y * scale + sy][out_x * scale + sx]
                acc_r += pr * (pa / 255.0)
                acc_g += pg * (pa / 255.0)
                acc_b += pb * (pa / 255.0)
                acc_a += pa

        avg_a = acc_a / samples
        if avg_a == 0:
            return (0, 0, 0, 0)
        return (
            int(acc_r / (acc_a / 255.0)),
            int(acc_g / (acc_a / 255.0)),
            int(acc_b / (acc_a / 255.0)),
            int(avg_a)
        )

    return generate_png(size, size, get_downsampled_pixel)

def create_ico_file(png_32_bytes, png_16_bytes):
    """
    Creates a simple Windows .ico file containing 16x16 and 32x32 PNG images.
    """
    ico = bytearray()
    # ICONDIR header: Reserved (0), Type (1=ICO), Count (2)
    ico.extend(struct.pack('<HHH', 0, 1, 2))

    offset = 6 + (16 * 2) # Header + 2 Directory entries

    # Directory entry 1: 32x32
    ico.extend(struct.pack('BBBBHHII', 32, 32, 0, 0, 1, 32, len(png_32_bytes), offset))
    offset += len(png_32_bytes)

    # Directory entry 2: 16x16
    ico.extend(struct.pack('BBBBHHII', 16, 16, 0, 0, 1, 32, len(png_16_bytes), offset))

    # ImageData
    ico.extend(png_32_bytes)
    ico.extend(png_16_bytes)

    return bytes(ico)

if __name__ == '__main__':
    print("Rendering IBUILD icons...")

    png_16 = render_ibuild_icon(16)
    png_32 = render_ibuild_icon(32)
    png_64 = render_ibuild_icon(64)
    png_192 = render_ibuild_icon(192)
    png_512 = render_ibuild_icon(512)
    png_m192 = render_ibuild_icon(192, maskable=True)
    png_m512 = render_ibuild_icon(512, maskable=True)

    # Write files
    os.makedirs('web/icons', exist_ok=True)

    with open('web/favicon.png', 'wb') as f:
        f.write(png_32)
    print("✓ Created web/favicon.png (32x32)")

    with open('web/favicon-16x16.png', 'wb') as f:
        f.write(png_16)
    print("✓ Created web/favicon-16x16.png (16x16)")

    with open('web/favicon-32x32.png', 'wb') as f:
        f.write(png_32)
    print("✓ Created web/favicon-32x32.png (32x32)")

    ico_bytes = create_ico_file(png_32, png_16)
    with open('web/favicon.ico', 'wb') as f:
        f.write(ico_bytes)
    print("✓ Created web/favicon.ico")

    with open('web/icons/Icon-192.png', 'wb') as f:
        f.write(png_192)
    print("✓ Created web/icons/Icon-192.png (192x192)")

    with open('web/icons/Icon-512.png', 'wb') as f:
        f.write(png_512)
    print("✓ Created web/icons/Icon-512.png (512x512)")

    with open('web/icons/Icon-maskable-192.png', 'wb') as f:
        f.write(png_m192)
    print("✓ Created web/icons/Icon-maskable-192.png")

    with open('web/icons/Icon-maskable-512.png', 'wb') as f:
        f.write(png_m512)
    print("✓ Created web/icons/Icon-maskable-512.png")

    print("\nAll favicons and app icons successfully generated!")
