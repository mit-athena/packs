# $Id: root.profile,v 1.2 1997-12-28 17:47:38 ghudson Exp $

# Set the interrupt character to Ctrl-c and do clean backspacing.
if [ -t 0 ]
then
	stty intr '^C' echoe 
fi

# Set the TERM environment variable
if [ -d /usr/lib/terminfo ]
then
	eval `tset -s -Q`
fi

# save tty state in a file where wsh can find it
if [ ! -f $HOME/.wshttymode -a -t 0 ]
then
    stty -g > $HOME/.wshttymode
fi

# Set the default X server.
if [ ${DISPLAY:-setdisplay} = setdisplay ]
then
    if [ ${REMOTEHOST:-islocal} != islocal ]
    then
        DISPLAY=${REMOTEHOST}:0
    else
        DISPLAY=:0
    fi
    export DISPLAY
fi

#
# Athena tweaks
#
PATH=/srvd/patch:/usr/athena/bin:/etc/athena:/bin/athena:/usr/sbin:/usr/bsd:/sbin:/usr/bin:/bin:/etc:/usr/athena/etc:/usr/etc:/usr/bin/X11
export PATH
