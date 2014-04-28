#!/bin/sh
# rsync backup to zfs and creating snapshots with zfsnap
# Copyright 2014 Alexander Dahl <alex@netz39.de>

set -e

# set your os paths here
DATE='/bin/date'
RSYNC='/usr/bin/rsync'
SSH='/usr/bin/ssh'
ZFSNAP='/usr/sbin/zfSnap'

# function definitions
print_usage() {
        echo "Usage: $0 remotehost remotepath localzfs"
        echo ''
        echo 'Options:'
        echo '  -h             this help'
        echo '  -s sparseconf  config file for sparse trees'
}

# "main"

# we only use classic getopt because this runs on linux and freebsd
ARGS=`getopt hs: $*`
if [ $? -ne 0 ]
then
        print_usage
        exit 2
fi
set -- $ARGS

while true
do
        case "$1" in
                -h)
                        print_usage
                        shift
                        ;;
                -s)
                        SPARSE_CONFIG="$2"
                        shift; shift
                        ;;
                --)
                        shift; break;;
        esac
done

# sync with rsync
if [ -z "${SPARSE_CONFIG}" ]
then
    echo "> syncing ${1}:${2}"
    ${RSYNC} --stats -zaH --delete -e "${SSH} -i /root/.ssh/backup" ${1}:${2}/ /${3}
    echo ''
else
    echo "using ${SPARSE_CONFIG} as sparse tree config"
fi

# take snapshot
DAY_OF_MONTH="$(${DATE} +%d)"
DAY_OF_WEEK="$(${DATE} +%u)"

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
