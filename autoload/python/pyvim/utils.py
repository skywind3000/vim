#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# utils.py - 
#
# Created by skywind on 2023/09/11
# Last Modified: 2023/09/11 00:31:31
#
#======================================================================
import sys
import vim



#----------------------------------------------------------------------
# get cursor position
#----------------------------------------------------------------------
def cursor_get() -> tuple[int, int]:
    lnum = vim.eval('line(".")')
    column = vim.eval('col(".")')
    return (int(lnum), int(column))

# print(cursor_get())
