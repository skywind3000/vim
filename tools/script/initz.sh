#! /bin/sh


#----------------------------------------------------------------------
# parameters
#----------------------------------------------------------------------
INITZ_HOME="$1"
INITZ_CMD="$2"
INITZ_WAIT=${3:-1}


#----------------------------------------------------------------------
# internal variable
#----------------------------------------------------------------------
INITZ_SLEEP=""


#----------------------------------------------------------------------
# initz_start service
#----------------------------------------------------------------------
initz_start() {
	trap "" INT QUIT TSTP EXIT
	if [ -d "$INITZ_HOME" ]; then
		echo "Launching initialization scripts"
		for f in $INITZ_HOME/I*; do
			[ -e "$f" ] && . "$f"
		done
		for f in $INITZ_HOME/S*; do
			[ -x "$f" ] && "$f" start
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
}


#----------------------------------------------------------------------
# initz_stop service
#----------------------------------------------------------------------
initz_stop() {
	trap "" INT QUIT TSTP EXIT
	if [ -d "$INITZ_HOME" ]; then
		echo "Launching termination scripts"
		for f in $INITZ_HOME/K*; do
			[ -x "$f" ] && "$f" stop
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
	if [ -n "$INITZ_WAIT" ]; then
		/bin/sleep "$INITZ_WAIT"
	fi
}


#----------------------------------------------------------------------
# execute scripts
#----------------------------------------------------------------------
initz_execute() {
	if [ -d "$INITZ_HOME" ]; then
		echo "Executing initialization scripts"
		for f in $INITZ_HOME/I*; do
			[ -e "$f" ] && . "$f"
		done
		for f in $INITZ_HOME/E*; do
			[ -x "$f" ] && "$f"
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
}


#----------------------------------------------------------------------
# reinitz_start service
#----------------------------------------------------------------------
initz_restart() {
	initz_stop 
	initz_start
}


#----------------------------------------------------------------------
# keep service
#----------------------------------------------------------------------
initz_term() {
	initz_stop
	[ -n "$INITZ_SLEEP" ] && kill $INITZ_SLEEP 2> /dev/null
	INITZ_SLEEP=""
	exit 0
}

initz_keep() {
	initz_start
	trap initz_term TERM INT TSTP QUIT EXIT
	while : 
	do
		/bin/sleep 3600 &
		INITZ_SLEEP=$!
		wait $!
	done
}


#----------------------------------------------------------------------
# main routine
#----------------------------------------------------------------------
initz_help() {
	echo "usage: $0 TARGET {start|stop|restart|keep|execute}"
	exit 0
}

if [ -z "$INITZ_CMD" ] || [ -z "$INITZ_HOME" ]; then
	initz_help
	exit 0
fi

case "$INITZ_CMD" in
	start)
		initz_start
		;;
	stop)
		initz_stop
		;;
	restart)
		initz_restart
		;;
	keep)
		initz_keep
		;;
	execute)
		initz_execute
		;;
	*)
		initz_help
		exit 0
esac




