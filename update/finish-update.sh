#!/bin/sh
# $Id: finish-update.sh,v 1.6 1997-05-26 00:20:44 ghudson Exp $

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

export PATH
CONFDIR=/etc/athena
LIBDIR=/srvd/usr/athena/lib/update
SERVERDIR=/var/server
PATH=/os/bin:/os/etc:/srvd/etc/athena:/srvd/bin/athena:/os/usr/bin:/srvd/usr/athena/etc:/os/usr/ucb:/os/usr/bsd:$LIBDIR:/bin:/etc:/usr/bin:/usr/ucb:/usr/bsd
HOSTTYPE=`/srvd/bin/athena/machtype`
CONFCHG=/var/athena/update.confchg
CONFVARS=/var/athena/update.confvars
AUXDEVS=/var/athena/update.auxdevs
OLDBINS=/var/athena/update.oldbins
DEADFILES=/var/athena/update.deadfiles

. $CONFDIR/rc.conf
newvers=`awk '{a=$7} END {print a}' $CONFDIR/version`

case "$HOSTTYPE" in
sgi)
	# Un-suppress network daemons.
	echo "Un-suppressing network daemons for next reboot"
	chkconfig -f suppress-network-daemons off
	;;
sun4)
	# On Solaris we get run before inetsvc (since we don't want to run
	# inetd), which means named isn't running.  Run it.
	/usr/sbin/in.named
	;;
esac

# Make sure we see the right cells as setuid.
sh /etc/athena/config_afs

# Do auxiliary device installs.
if [ -s "$AUXDEVS" ]; then
	drvrs=`cat "$AUXDEVS"`
	for i in $drvrs; do
		/srvd/install/aux.devs/$i
	done
fi

# Remove the version script state files.
rm -f "$CONFCHG" "$CONFVARS" "$AUXDEVS" "$OLDBINS" "$DEADFILES"

echo "Updating version"
echo "Athena Workstation ($HOSTTYPE) Version $newvers `date`" >> \
	${CONFDIR}/version

# Re-customize the workstation
if [ "$PUBLIC" = "true" ]; then
	rm -rf "$SERVERDIR"
fi

if [ -d "$SERVERDIR" ]; then
	echo "Running mkserv."
	/srvd/usr/athena/bin/mkserv -v update < /dev/null
fi
