#!/bin/sh
#
# Script to verify PGP signature of mail message
#

# Location of public key ring: pubring.pgp
PGPPATH=/afs/athena/system/config/keys/early-warn; export PGPPATH

# Nothing below this line needs to be modified to use a different keyring.

if [ $# -eq 0 ]; then
	# Called with no arguments.  Use current MH message number.
	  cd `show -noheader -showproc pwd`
	  msgfile=`show -noheader -showproc echo $1` || exit 1
else
	# Argument; either filename, dash,  or MH message number
	if [ $1 = "-" ]; then
		# standard input
		msgfile=-f
	elif [ -s $1 ]; then
		# Filename
		msgfile=$1
	else
		# MH message number
		cd `show -noheader -showproc pwd`
		msgfile=`show -noheader -showproc echo $1` || exit 1
	fi
fi

TESTECHO=`echo -n`
case "$TESTECHO" in
   -n) N=''; C='\c';;
   *)  N='-n'; C='';;
esac

outfile=/usr/tmp/verify.$$
rm -f $outfile
page=${PAGER-more}
echo "Please make sure the following says the signature is good and that"
echo "the message is addressed to you."

/bin/athena/attachandrun pgp pgp $msgfile -o $outfile +verbose=0
if [ $? = 0 ]; then
	echo ""
	echo $N "The message follows. Press ENTER to continue... $C"
	read foo
	echo "==============="
	$page $outfile
	rm -f $outfile
fi
