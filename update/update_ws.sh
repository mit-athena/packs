#!/bin/sh
# $Id: update_ws.sh,v 1.31 1998-03-27 01:21:19 ghudson Exp $

# Copyright 1996 by the Massachusetts Institute of Technology.
#
# Permission to use, copy, modify, and distribute this
# software and its documentation for any purpose and without
# fee is hereby granted, provided that the above copyright
# notice appear in all copies and that both that copyright
# notice and this permission notice appear in supporting
# documentation, and that the name of M.I.T. not be used in
# advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
# M.I.T. makes no representations about the suitability of
# this software for any purpose.  It is provided "as is"
# without express or implied warranty.

# update_ws (also known as auto_update)
#
# Check that an update is needed, and make sure the conditions necessary
# for a successful update are met. Then prepare the machine for update,
# and run do-update.

trap "" 1 15

export CONFDIR LIBDIR PATH HOSTTYPE
CONFDIR=/etc/athena
LIBDIR=/srvd/usr/athena/lib/update
PATH=/bin:/etc:/usr/bin:/usr/ucb:/usr/bsd:/os/bin:/os/etc:/srvd/etc/athena:/srvd/bin/athena:/os/usr/bin:/srvd/usr/athena/etc:/os/usr/ucb:/os/usr/bsd:$LIBDIR
HOSTTYPE=`/bin/athena/machtype`

case "$0" in
*auto_update)
	method=Auto
	;;
*)
	method=Manual
	;;
esac

# The -r option specifies that the update is remote and that we shouldn't
# give the user a shell after the reboot.
while getopts r opt; do
	case "$opt" in
	r)
		method=Remote
		;;
	\?)
		echo "$0 [-r] [reactivate|rc]" 1>&2
		exit 1
		;;
	esac
done
shift `expr $OPTIND - 1`
why="$1"

if [ "`whoami`" != "root" ];  then
	echo "You are not root.  This update script must be run as root."
	exit 1
fi

# If /srvd is not mounted, quit.
if [ ! -d /srvd/bin ]; then
	exit 1
fi

if [ ! -f "$CONFDIR/version" ]; then
	echo "Athena Update (???) Version 0.0A Mon Jan 1 00:00:00 EDT 0000" \
		> "$CONFDIR/version"
fi

newvers=`awk '{a=$5}; END{print a}' /srvd/.rvdinfo`
version=`awk '{a=$5}; END{print a}' "$CONFDIR/version"`

# A temporary backward compatibility hack, necessary as long as there are
# 7.7 and 8.0 machines upgrading to the new release.
case "$version" in
[0-9].[0-9][A-Z])
	version=`echo $version | awk '{ print substr($1, 1, 3) "." \
		index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", substr($1, 4, 1)) - 1; }'`
	;;
esac

if [ -f "$CONFDIR/rc.conf" ]; then
	. "$CONFDIR/rc.conf"
else
	export PUBLIC AUTOUPDATE HOST
	PUBLIC=true
	AUTOUPDATE=true
	HOST=`hostname`
fi

# Make sure /var/athena exists (it was introduced in 8.1.0) so we have a
# place to put the temporary clusterinfo file and the desync state file
# and the update log.
if [ ! -d /var/athena ]; then
	mkdir -m 755 /var/athena
fi

# Get clusterinfo for the version in /srvd/.rvdinfo to determine what
# to attach for /install on SGIs.  This also sets NEW_TESTING_RELEASE
# and NEW_PRODUCTION_RELEASE if there are new releases available.  If
# SGIs are ever brought back to the normal /srvd vs. /os distinction,
# we can just run /etc/athena/save_cluster_info like we used to before
# version 1.9 of this file.
AUTOUPDATE=false /bin/athena/getcluster -b `hostname` "$newvers" > \
	/var/athena/clusterinfo.bsh.update
if [ $? -ne 0 -o ! -s /var/athena/clusterinfo.bsh.update ]; then
	# No updates for machines without cluster info.
	if [ "$method" != Auto ]; then
		echo "Cannot find Hesiod information for this machine;"
		echo "aborting update."
	fi
	exit 1
fi
. /var/athena/clusterinfo.bsh.update
rm -f /var/athena/clusterinfo.bsh.update

# Check if we're already in the middle of an update.
if [ "$version" = Update -o "$version" = Reboot ]; then
	if [ ! -f /var/tmp/update.check ]; then
		logger -t $HOST -p user.notice at revision $version
		touch /var/tmp/update.check
	fi

	echo "This system is in the middle of an update.  Please contact"
	echo "Athena Hotline at x3-1410. Thank you. -Athena Operations"
	exit 1
fi

# Find out if the version in /srvd/.rvdinfo is newer than
# /etc/athena/version.  Distinguish between major, minor, and patch
# releases so that we can desynchronize patch releases.
packsnewer=`echo "$newvers $version" | awk '{
	split($1, v1, ".");
	split($2, v2, ".");
	if (v1[1] + 0 > v2[1] + 0)
		print "major";
	else if (v1[1] + 0 == v2[1] + 0 && v1[2] + 0 > v2[2] + 0)
		print "minor";
	else if (v1[1] == v2[1] && v1[2] == v2[2] && v1[3] + 0 > v2[3] + 0)
		print "patch"; }'`

# If the packs aren't any newer, print an appropriate message and exit.
if [ -z "$packsnewer" ]; then
	if [ "$method" != Auto ]; then
		# User ran update_ws; display something appropriate.
		if [ -n "$NEW_PRODUCTION_RELEASE" -o \
		     -n "$NEW_TESTING_RELEASE" ]; then
			echo "Your workstation software already matches the"
			echo "version on the system packs.  You must manually"
			echo "attach a newer version of the system packs to"
			echo "update beyond this point."
		else
			echo "It appears you already have this update."
		fi
	else
		# System ran auto_update; point out new releases if available.
		if [ -n "$NEW_PRODUCTION_RELEASE" ]; then
			/bin/cat <<EOF

A new Athena release ($NEW_PRODUCTION_RELEASE) is available.  Since it may be
incompatible with your workstation software, your workstation
is still using the old system packs.  Please contact Athena
Hotline (x3-1410) to have your workstation updated.
EOF
		fi
		if [ -n "$NEW_TESTING_RELEASE" ]; then
			/bin/cat << EOF

A new Athena release ($NEW_TESTING_RELEASE) is now in testing.  You are
theoretically interested in this phase of testing, but
because there may be bugs which would inconvenience
your work, you must update to this release manually.
Please contact Athena Hotline (x3-1410) if you have
not received instructions on how to do so.
EOF
		fi
	fi
	exit 0
fi

# The packs are newer, but if we were run as auto_update, we don't want to do
# an update unless the machine is autoupdate (or public).
if [ "$method" = Auto -a "$AUTOUPDATE" != true -a "$PUBLIC" != true ]; then
	cat <<EOF

	A new version of Athena software is now available.
	Please contact Athena Operations to get more information
	on how to update your workstation yourself, or to schedule
	us to do it for you. Thank you.  -Athena Operations
EOF
	if [ ! -f /var/tmp/update.check ]; then
		logger -t $HOST -p user.notice at revision $version
		cp /dev/null /var/tmp/update.check
	fi

	exit 1
fi

if [ "$method" = Auto -a "$packsnewer" = patch ]; then
	# There is a patch release available and we want to take the
	# update, but not necessarily right now.  Use desync to
	# stagger the update over a four-hour period.  (Use the
	# version from /srvd for now to make sure the -t option works,
	# since that option was not introduced until 8.1.)  Note
	# that we only do desynchronization here for patch releases.
	# Desynchronization for major or minor releases is handled in
	# getcluster, since we don't want the workstation to run with
	# a new, possibly incompatible version of the packs.

	/srvd/etc/athena/desync -t /var/athena/update.desync 14400
	if [ $? -ne 0 ]; then
		exit 0
	fi
fi

# On SGIs, check if there are 20MB of disk space left, since we don't keep
# our own partition around.
case "$HOSTTYPE" in
sgi)
	if [ "`df -k / | awk '/root/ { print $5; }'`" -lt 20480 ]; then
		echo "Root partition low on space (less than 20MB); not"
		echo "performing update."
		exit 1
	fi
esac

# If this is a private workstations, make sure we can recreate the mkserv
# state of the machine after the update.
if [ -d /var/server ] ; then
	/srvd/usr/athena/bin/mkserv updatetest
	if [ $? -ne 0 ]; then
		echo "mkserv services cannot be found for all services."
		echo "Update cannot be performed."
		exit 1
	fi
fi

# On SGIs, make sure /install exists.  (This should hopefully go away if
# SGIs are ever brought back to the normal /srvd vs. /os way of doing
# things.)
case "$HOSTTYPE" in
sgi)
	if [ ! -n "$INSTLIB" ]; then
		echo "No installation library set in Hesiod information,"
		echo "aborting update."
		exit 1
	fi

	/bin/athena/attach -q -h -n -o hard $INSTLIB
	if [ ! -d /install/install ]; then
		echo "Installation directory can't be found, aborting update."
		exit 1
	fi
	;;
esac

# Tell dm to shut down everything and sleep forever during the update.
if [ "$method" = Auto -a "$why" = reactivate ]; then
	if [ -f /var/athena/dm.pid ]; then
		kill -FPE `cat /var/athena/dm.pid`
	fi
	# 8.0 and prior machines still have /etc/athena/dm.pid.
	if [ -f /etc/athena/dm.pid ]; then
		kill -FPE `cat /etc/athena/dm.pid`
	fi

	if [ -f /etc/init.d/axdm ]; then
		/etc/init.d/axdm stop
 	fi

	sleep 2
	if [ "$HOSTTYPE" = sgi ]; then
		exec 1>/dev/tport 2>&1
	fi
fi

# Everything is all set; do the actual update.
rm -f /var/athena/update.log
if [ "$method" = Auto ]; then
	echo
	echo THIS WORKSTATION IS ABOUT TO UNDERGO AN AUTOMATIC SOFTWARE UPDATE.
	echo THIS PROCEDURE MAY TAKE SOME TIME.
	echo
	echo PLEASE DO NOT DISTURB IT WHILE THIS IS IN PROGRESS.
	echo
	exec sh "$LIBDIR/do-update" "$method" "$version" "$newvers" \
		< /dev/null 2>&1 | tee /var/athena/update.log
else
	exec sh "$LIBDIR/do-update" "$method" "$version" "$newvers" \
		2>&1 | tee /var/athena/update.log
fi
