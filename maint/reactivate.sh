#!/bin/sh
# Script to bounce the packs on an Athena workstation
#
# $Id: reactivate.sh,v 1.30 1997-05-08 07:31:17 ghudson Exp $

trap "" 1 15

PATH=/bin:/bin/athena:/usr/ucb:/usr/bin; export PATH

umask 22
. /etc/athena/rc.conf

# Default options
dflags="-clean"


# Set various flags (based on environment and command-line)
if [ "$1" = "-detach" ]; then dflags=""; fi

if [ "$1" = "-prelogin" ]; then
	if [ "${PUBLIC}" = "false" ]; then exit 0; fi
	echo "Cleaning up..." >> /dev/console
else
	full=true
fi

if [ "${USER}" = "" ]; then
	exec 1>/dev/console 2>&1
	quiet=-q
else
	echo Reactivating workstation...
	quiet=
fi

case "${SYSTEM}" in
ULTRIX*)
	cp=/bin/cp
	;;
*)
	cp="/bin/cp -p"
esac

# Flush all NFS uid mappings
/bin/athena/fsid $quiet -p -a

# Sun attach bug workaround. Attach apparently loses on some options.
# fsid does not though, so we zap them only after executing fsid.
if [ "${MACHINE}" = "SUN4" ]; then
	dflags=""
	quiet=""
fi

# Tell the Zephyr hostmanager to reset state
if [ -f /var/athena/zhm.pid -a "${ZCLIENT}" = "true" ] ; then 
	/bin/kill -HUP `/bin/cat /var/athena/zhm.pid`
fi

case "${MACHINE}" in
RSAIX)
	chmod 666 /dev/hft
	;;
*)
	;;
esac

# kdestroy from /tmp any ticket files that may have escaped other methods
# of destruction, before we clear /tmp.
for i in /tmp/tkt* /tmp/krb5cc*; do
  KRBTKFILE=$i /usr/athena/bin/kdestroy -f
done

if [ $full ]; then		# START tmp clean
# Clean temporary areas (including temporary home directories)
case "${MACHINE}" in
RSAIX)
	find /tmp -depth \( -type f -o -type l \) -print | xargs /bin/rm -f -
	find /tmp -depth -type d -print | xargs /bin/rmdir 1>/dev/null 2>&1
	;;

SUN4)
	cp -p /tmp/ps_data /usr/tmp/ps_data
	/bin/rm -rf /tmp/* > /dev/null 2>&1
	cp -p /usr/tmp/ps_data /tmp/ps_data
	/bin/rm -f /usr/tmp/ps_data
	;;
INDY)
	/bin/rm -rf /tmp/* > /dev/null 2>&1
	;;
*)
	/bin/mv /tmp/.X11-unix /tmp/../.X11-unix
	/bin/rm -rf /tmp/ > /dev/null 2>&1
	/bin/mv /tmp/../.X11-unix /tmp/.X11-unix
	;;
esac
fi				# END tmp clean

# Copy in latest password file
if [ "${PUBLIC}" = "true" ]; then
	if [ -r /srvd/etc/passwd ]; then
	    ${cp} /srvd/etc/passwd /etc/passwd.local
	    chmod 644 /etc/passwd.local
	    chown root /etc/passwd.local
	fi
	if [ -r /srvd/etc/shadow ]; then
	    ${cp} /srvd/etc/shadow /etc/shadow.local
	    chmod 600 /etc/shadow.local
	    chown root /etc/shadow.local
	fi
fi

# Restore password and group files
case "${MACHINE}" in
RSAIX)
	;;
*)
	if [ -f /etc/passwd.local ] ; then
	    ${cp} /etc/passwd.local /etc/ptmp && /bin/mv -f /etc/ptmp /etc/passwd
	fi
	if [ -f /etc/shadow.local ] ; then
	    ${cp} /etc/shadow.local /etc/stmp && /bin/mv -f /etc/stmp /etc/shadow
	fi
	if [ -f /etc/group.local ] ; then
	    ${cp} /etc/group.local /etc/gtmp && /bin/mv -f /etc/gtmp /etc/group
	fi
	;;
esac

if [ $full ]; then		# START AFS reconfig
# Reconfigure AFS state
if [ "${AFSCLIENT}" != "false" ]; then
    /etc/athena/config_afs > /dev/null 2>&1 &
fi
fi				# END AFS reconfig

# punt any processes owned by users not in /etc/passwd
/etc/athena/cleanup -passwd

if [ $full ]; then		# START time-consuming stuff
# Finally, detach all remote filesystems
/bin/athena/detach -O -h -n $quiet $dflags -a

# Now start activate again
/etc/athena/save_cluster_info

if [ -f /var/athena/clusterinfo.bsh ] ; then
	. /var/athena/clusterinfo.bsh
else
	if [ "${RVDCLIENT}" = "true" ]; then
		echo "Can't find library servers."
		exit 1
	fi
fi

if [ "${RVDCLIENT}" = "true" ]; then
	/bin/athena/attach	$quiet -h -n -o hard -O $SYSLIB
fi

# Perform an update if appropriate
/srvd/auto_update reactivate

fi				# END time-consuming stuff

if [ -f /usr/athena/bin/access_off ]; then /usr/athena/bin/access_off; fi

if [ $full ]; then		# START reactivate.local
if [ -f /etc/athena/reactivate.local ]; then
	/etc/athena/reactivate.local
fi
fi				# END reactivate.local

exit 0
