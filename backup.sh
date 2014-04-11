#!/bin/sh
#
# Usage: $0 remotehost remotepath localzfs
 
DAY_OF_MONTH=$(date +%d)
DAY_OF_WEEK=$(date +%u)
 
echo "> syncing ${1}:${2}"
/usr/bin/rsync --stats -zaH --delete -e 'ssh -i /root/.ssh/backup' ${1}:${2}/ /${3}
if [ "${DAY_OF_MONTH}" = '12' ]
then
echo '> creating monthly zfs snapshot'
/usr/sbin/zfSnap -v -s -S -a 2y ${3}
elif [ "${DAY_OF_WEEK}" = '3' ]
then
echo '> creating weekly zfs snapshot'
/usr/sbin/zfSnap -v -s -S -a 2m ${3}
else
echo '> creating daily zfs snapshot'
/usr/sbin/zfSnap -v -s -S -a 2w ${3}
fi