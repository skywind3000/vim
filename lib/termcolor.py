#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# termcolor.py - 
#
# Created by skywind on 2024/01/11
# Last Modified: 2024/01/11 16:36:26
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import math
import os


#----------------------------------------------------------------------
# 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
    unicode = str


#----------------------------------------------------------------------
# xterm 256 color palette
#----------------------------------------------------------------------
PALETTE = [
    0x000000, 0x800000, 0x008000, 0x808000, 0x000080, 0x800080, 0x008080,
    0xc0c0c0, 0x808080, 0xff0000, 0x00ff00, 0xffff00, 0x0000ff, 0xff00ff,
    0x00ffff, 0xffffff, 0x000000, 0x00005f, 0x000087, 0x0000af, 0x0000d7,
    0x0000ff, 0x005f00, 0x005f5f, 0x005f87, 0x005faf, 0x005fd7, 0x005fff,
    0x008700, 0x00875f, 0x008787, 0x0087af, 0x0087d7, 0x0087ff, 0x00af00,
    0x00af5f, 0x00af87, 0x00afaf, 0x00afd7, 0x00afff, 0x00d700, 0x00d75f,
    0x00d787, 0x00d7af, 0x00d7d7, 0x00d7ff, 0x00ff00, 0x00ff5f, 0x00ff87,
    0x00ffaf, 0x00ffd7, 0x00ffff, 0x5f0000, 0x5f005f, 0x5f0087, 0x5f00af,
    0x5f00d7, 0x5f00ff, 0x5f5f00, 0x5f5f5f, 0x5f5f87, 0x5f5faf, 0x5f5fd7,
    0x5f5fff, 0x5f8700, 0x5f875f, 0x5f8787, 0x5f87af, 0x5f87d7, 0x5f87ff,
    0x5faf00, 0x5faf5f, 0x5faf87, 0x5fafaf, 0x5fafd7, 0x5fafff, 0x5fd700,
    0x5fd75f, 0x5fd787, 0x5fd7af, 0x5fd7d7, 0x5fd7ff, 0x5fff00, 0x5fff5f,
    0x5fff87, 0x5fffaf, 0x5fffd7, 0x5fffff, 0x870000, 0x87005f, 0x870087,
    0x8700af, 0x8700d7, 0x8700ff, 0x875f00, 0x875f5f, 0x875f87, 0x875faf,
    0x875fd7, 0x875fff, 0x878700, 0x87875f, 0x878787, 0x8787af, 0x8787d7,
    0x8787ff, 0x87af00, 0x87af5f, 0x87af87, 0x87afaf, 0x87afd7, 0x87afff,
    0x87d700, 0x87d75f, 0x87d787, 0x87d7af, 0x87d7d7, 0x87d7ff, 0x87ff00,
    0x87ff5f, 0x87ff87, 0x87ffaf, 0x87ffd7, 0x87ffff, 0xaf0000, 0xaf005f,
    0xaf0087, 0xaf00af, 0xaf00d7, 0xaf00ff, 0xaf5f00, 0xaf5f5f, 0xaf5f87,
    0xaf5faf, 0xaf5fd7, 0xaf5fff, 0xaf8700, 0xaf875f, 0xaf8787, 0xaf87af,
    0xaf87d7, 0xaf87ff, 0xafaf00, 0xafaf5f, 0xafaf87, 0xafafaf, 0xafafd7,
    0xafafff, 0xafd700, 0xafd75f, 0xafd787, 0xafd7af, 0xafd7d7, 0xafd7ff,
    0xafff00, 0xafff5f, 0xafff87, 0xafffaf, 0xafffd7, 0xafffff, 0xd70000,
    0xd7005f, 0xd70087, 0xd700af, 0xd700d7, 0xd700ff, 0xd75f00, 0xd75f5f,
    0xd75f87, 0xd75faf, 0xd75fd7, 0xd75fff, 0xd78700, 0xd7875f, 0xd78787,
    0xd787af, 0xd787d7, 0xd787ff, 0xd7af00, 0xd7af5f, 0xd7af87, 0xd7afaf,
    0xd7afd7, 0xd7afff, 0xd7d700, 0xd7d75f, 0xd7d787, 0xd7d7af, 0xd7d7d7,
    0xd7d7ff, 0xd7ff00, 0xd7ff5f, 0xd7ff87, 0xd7ffaf, 0xd7ffd7, 0xd7ffff,
    0xff0000, 0xff005f, 0xff0087, 0xff00af, 0xff00d7, 0xff00ff, 0xff5f00,
    0xff5f5f, 0xff5f87, 0xff5faf, 0xff5fd7, 0xff5fff, 0xff8700, 0xff875f,
    0xff8787, 0xff87af, 0xff87d7, 0xff87ff, 0xffaf00, 0xffaf5f, 0xffaf87,
    0xffafaf, 0xffafd7, 0xffafff, 0xffd700, 0xffd75f, 0xffd787, 0xffd7af,
    0xffd7d7, 0xffd7ff, 0xffff00, 0xffff5f, 0xffff87, 0xffffaf, 0xffffd7,
    0xffffff, 0x080808, 0x121212, 0x1c1c1c, 0x262626, 0x303030, 0x3a3a3a,
    0x444444, 0x4e4e4e, 0x585858, 0x626262, 0x6c6c6c, 0x767676, 0x808080,
    0x8a8a8a, 0x949494, 0x9e9e9e, 0xa8a8a8, 0xb2b2b2, 0xbcbcbc, 0xc6c6c6,
    0xd0d0d0, 0xdadada, 0xe4e4e4, 0xeeeeee,
]


#----------------------------------------------------------------------
# extract color tuple
#----------------------------------------------------------------------
def color_extract(rgb):
    if isinstance(rgb, str):
        if rgb.startswith('#'):
            ic = int(rgb[1:], 16)
        else:
            return (0, 0, 0)
    elif isinstance(rgb, int):
        ic = rgb
    elif isinstance(rgb, tuple) or isinstance(rgb, list):
        return tuple(rgb[:3])
    elif sys.version_info[0] < 3:
        if isinstance(rgb, unicode):  # noqa: F821
            ic = int(rgb[1:], 16)
        else:
            return (0, 0, 0)
    else:
        return (0, 0, 0)
    r = (ic >> 16) & 0xff
    g = (ic >> 8) & 0xff
    b = (ic >> 0) & 0xff
    return (r, g, b)


#----------------------------------------------------------------------
# bestfit
#----------------------------------------------------------------------
def bestfit256(color):
    r, g, b = color_extract(color)
    nearest_index = -1
    nearest_dist = 0xff * 0xff * 64 * 64 * 4
    for index in range(256):
        color = PALETTE[index]
        G = (color >> 8) & 0xff
        dist = (((g - G) * 59) ** 2) 
        if dist >= nearest_dist:
            continue
        R = (color >> 16) & 0xff
        dist += (((r - R) * 30) ** 2)
        if dist >= nearest_dist:
            continue
        B = (color >> 0) & 0xff
        dist += (((b - B) * 11) ** 2)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest_index = index
    return nearest_index


#----------------------------------------------------------------------
# match256: approximate match
#----------------------------------------------------------------------
def match256(color):
    def grey_number(x):
        if x < 14: return 0
        n = (x - 8) // 10
        m = (x - 8) % 10
        return (m >= 5) and (n + 1) or n
    def grey_level(n):
        if n == 0:
            return 0
        return 8 + (n * 10)
    def grey_color(n):
        if n == 0: return 16
        elif n == 25:
            return 231
        return 231 + n
    def rgb_number(x):
        if x < 75:
            return 0
        n = (x - 55) // 40
        m = (x - 55) % 40
        if m < 20:
            return n
        return n + 1
    def rgb_level(n):
        if n == 0:
            return 0
        return 55 + (n * 40)
    def rgb_color(x, y, z):
        return 16 + x * 36 + y * 6 + z
    def match_color(r, g, b):
        gx = grey_number(r)
        gy = grey_number(g)
        gz = grey_number(b)
        x = rgb_number(r)
        y = rgb_number(g)
        z = rgb_number(b)
        if gx == gy and gy == gz:
            dgr = grey_level(gx) - r
            dgg = grey_level(gy) - g
            dgb = grey_level(gz) - b
            dgrey = dgr * dgr + dgg * dgg + dgb * dgb
            dr = rgb_level(gx) - r
            dg = rgb_level(gy) - g
            db = rgb_level(gz) - b
            drgb = dr * dr + dg * dg + db * db
            if dgrey < drgb:
                return grey_color(gx)
            else:
                return rgb_color(x, y, z)
        return rgb_color(x, y, z)
    r = (color >> 16) & 0xff
    g = (color >>  8) & 0xff
    b = (color >>  0) & 0xff
    return match_color(r, g, b)


#----------------------------------------------------------------------
# color error 
#----------------------------------------------------------------------
def color_error(c1, c2):
    r1 = (c1 >> 16) & 0xff
    g1 = (c1 >>  8) & 0xff
    b1 = (c1 >>  0) & 0xff
    r2 = (c2 >> 16) & 0xff
    g2 = (c2 >>  8) & 0xff
    b2 = (c2 >>  0) & 0xff
    dx = (r1 - r2) * 30
    dy = (g1 - g2) * 59
    dz = (b1 - b2) * 11
    return dx * dx + dy * dy + dz * dz


#----------------------------------------------------------------------
# round 
#----------------------------------------------------------------------
def color_distance(c1, c2):
    dd = color_error(c1, c2)
    dist = math.isqrt(dd)
    return dist // 100


#----------------------------------------------------------------------
# test1
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print(bestfit256(0x112233))
        print(match256(0x112233))
        return 0
    def test2():
        for index in range(256):
            c1 = PALETTE[index]
            m1 = bestfit256(c1)
            m1 = match256(c1)
            # print(m1)
            c2 = PALETTE[m1]
            print(index, m1, color_distance(c1, c2))
        return 0
    def test3():
        dists = {}
        for cc in range(1 << 15):
            r = ((cc >> 10) & 31) << 3
            g = ((cc >> 5) & 31) << 3
            b = ((cc >> 0) & 31) << 3
            m1 = bestfit256((r << 16) | (g << 8) | b)
            m2 = match256((r << 16) | (g << 8) | b)
            c1 = PALETTE[m1]
            c2 = PALETTE[m2]
            error = color_distance(c1, c2)
            dists[error] = dists.get(error, 0) + 1
        keys = list(dists.keys())
        keys.sort()
        for key in keys:
            print(key, dists[key])
        return 0
    test3()



