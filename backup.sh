#!/bin/sh

# set paths here
DATE='/bin/date'
RSYNC='/usr/bin/rsync'
SSH='/usr/bin/ssh'
ZFSNAP='/usr/sbin/zfSnap'

print_usage() {
        echo "Usage: $0 remotehost remotepath localzfs"
        echo ''
        echo 'Options:'
        echo '  -h             this help'
        echo '  -s sparseconf  config file for sparse trees'
}

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
                        echo "would have used '$2' as sparse tree config"
                        SPARSE_CONFIG="$2"
                        shift; shift
                        ;;
                --)
                        shift; break;;
        esac
done

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
