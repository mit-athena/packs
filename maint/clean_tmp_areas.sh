#!/bin/csh -f
#
# This script is intended to replace the following "finds" which were
#	intended to clean up /tmp, /usr/tmp and some other areas.
#
# 05 1 * * *	root	find /tmp -atime +1 -exec rm -f {} \;
# 10 1 * * *	root	cd /tmp; find . ! -name . -type d -mtime +1 -exec rm -r {} \;
# 15 1 * * *	root	find /usr/tmp -atime +2 -exec rm -f {} \;
# 20 1 * * *	root	cd /usr/tmp; find . ! -name . -type d -mtime +1 -exec rmdir {} \;
# 10 4 * * *	root	(cd /usr/spool/rwho; find . -name whod.\* -mtime +7 -exec rm -f {} \;)
# 15 4 * * *	root	(cd /usr/preserve; find . -mtime +7 -a -exec rm -f {} \;)
#
# It was discovered that on systems which do not have a /usr/tmp, and are
#	idle much of the time, such as VS2 workstations, the "05 1" & "10 1"
#	lines will delete everything in /tmp.  This allows the "20 1" line
#	to delete /tmp, since there is no /usr/tmp.  This allows "10 1" to
#	delete EVERYTHING on the disk which has not been accessed in 24
#	hours.  AAAAAAAARRRRRRRRGGGGGGGGHHHHHHHH!!!!!!!! From Berkeley.
set dirs =    (	/tmp/		/usr/tmp/	/usr/spool/rwho/ \
		/usr/preserve/)
set timeout = (	"-atime +1"	"-atime +2"	"-mtime +3" \
		"-mtime +3")

set j = 1
foreach i ($dirs)
	if ( -d $i ) then
		cd $i
		find . $timeout[$j] ! -type b ! -type c ! -type s -exec rm -f {} \; -print
		find . ! -name . -type d -mtime +1 -exec rmdir {} \; -print
	endif
@ j++
end	
