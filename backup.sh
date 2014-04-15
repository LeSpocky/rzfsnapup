#!/bin/sh
#
# Usage: $0 remotehost remotepath localzfs

# set paths here
DATE='/bin/date'
RSYNC='/usr/bin/rsync'
SSH='/usr/bin/ssh'
ZFSNAP='/usr/sbin/zfSnap'

DAY_OF_MONTH="$(${DATE} +%d)"
DAY_OF_WEEK="$(${DATE} +%u)"

echo "> syncing ${1}:${2}"
${RSYNC} --stats -zaH --delete -e "${SSH} -i /root/.ssh/backup" ${1}:${2}/ /${3}
echo ''

if [ "${DAY_OF_MONTH}" = '12' ]
then
        echo '> creating monthly zfs snapshot'
        ${ZFSNAP} -v -s -S -a 2y ${3}
elif [ "${DAY_OF_WEEK}" = '3' ]
then
        echo '> creating weekly zfs snapshot'
        ${ZFSNAP} -v -s -S -a 2m ${3}
else
        echo '> creating daily zfs snapshot'
        ${ZFSNAP} -v -s -S -a 2w ${3}
fi
echo ''
