#!/bin/sh

# $Id: quotawarn.sh,v 1.4 2007-04-09 17:13:19 ghudson Exp $

# Determine the user's home directory usage and quota.
qline=`quota -v -f "$USER" | awk '/^\// {print}'`
usage=`echo "$qline" | awk '{print $2}'`
quota=`echo "$qline" | awk '{print $3}'`
quota90=`expr "${quota:-0}" \* 9 / 10`

if [ -n "$usage" -a -n "$quota" ] && [ "$usage" -ge "$quota" ]; then
  zenity --error --text="
Your home directory usage exceeds your quota (${usage}KB
used out of ${quota}KB).  You will be unable to use
Athena normally until you free up space by deleting
unneeded files.  You may find the following command
useful to identify unneeded files:

  athrun consult helpquota"
elif [ -n "$usage" -a -n "$quota90" ] && [ "$usage" -ge "$quota90" ]; then
  zenity --info --text="
Your home directory usage is near your quota (${usage}KB
used out of ${quota}KB).  Consider removing unneeded
files to free up space.  You may find the following
command useful to identify unneeded files:

  athrun consult helpquota"
fi

# Determine the user's mail usage and quota.
qline=`mailquota | tail +2`
usage=`echo "$qline" | awk '{print $2}'`
quota=`echo "$qline" | awk '{print $3}'`
quota90=`expr "${quota:-0}" \* 9 / 10`

if [ -n "$usage" -a -n "$quota90" ] && [ "$usage" -ge "$quota90" ]; then
  zenity --info --text="
Your MIT mail usage is close to or exceeding your mail
quota (${usage}KB used out of ${quota}KB).  Consider
removing unneeded mail messages to free up space.  You
may find the following command useful to identify which
mail folders need the most attention:

  mailusage"
fi
