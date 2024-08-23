#! /bin/sh
# vim: set ts=4 sw=4 tw=0 noet ft=sh :


#----------------------------------------------------------------------
# fortune teller
#----------------------------------------------------------------------
FORTUNE=/usr/games/fortune
FORTUNES=/usr/share/games/fortunes

if [ -x $FORTUNE ]; then
        if [ -f $FORTUNES/debian-hints ]; then echo ""; $FORTUNE debian-hints; fi
        if [ -f $FORTUNES/wisdom ]; then echo ""; $FORTUNE wisdom; fi
        # if [ -f $FORTUNES/linux ]; then echo ""; fortune linux; fi
        echo ""
fi



