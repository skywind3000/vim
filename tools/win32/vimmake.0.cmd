@echo off


CD /D "%VIM_FILEDIR%"

echo emake -clean "%VIM_FILENAME%"
emake -clean "%VIM_FILENAME%"

