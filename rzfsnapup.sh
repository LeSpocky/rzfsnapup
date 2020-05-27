#!/bin/sh
# rsync backup to zfs and creating snapshots with zfsnap
# Copyright 2014,2016 Alexander Dahl <alex@netz39.de>

set -e
set +x

# set your os paths here
DATE='/bin/date'
RSYNC='/usr/local/bin/rsync'
SSH='/usr/bin/ssh'
ZFSNAP='/usr/local/sbin/zfSnap'

# function definitions
print_usage() {
	echo "Usage: $0 [options] remotehost remotepath localzfs"
	echo "(on FreeBSD put options _there_ directly after ${0} )"
	echo ''
	echo 'Options:'
	echo '  -h                this help'
	echo '  -i identity_file  path to private key file'
	echo '  -s sparseconf     config file for sparse trees'
	echo '  -x                pass --one-file-system to rsync'
}

# "main"

# we only use classic getopt because this runs on linux and freebsd
IDENTITY_FILE='/root/.ssh/backup'
X=''

ARGS=`getopt hi:s:x $*`
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
			exit 0
			;;
		-i)
			IDENTITY_FILE="$2"
			shift; shift
			;;
		-s)
			SPARSE_CONFIG="$2"
			shift; shift
			;;
		-x)
			X='--one-file-system'
			shift
			;;
		--)
			shift; break;;
	esac
done

# sync with rsync
if [ -z "${SPARSE_CONFIG}" ]
then
	echo "> syncing ${1}:${2}"
	${RSYNC} --stats -zahH ${X} --delete -e "${SSH} -i '${IDENTITY_FILE}'" ${1}:${2}/ /${3}
	echo ''
else
	if [ -f "${SPARSE_CONFIG}" ]
	then
		echo ">> using ${SPARSE_CONFIG} as sparse tree config"
		. ${SPARSE_CONFIG}
	else
		echo "sparse config '${SPARSE_CONFIG}' not found"
		exit 1
	fi

	for _idx in $(seq ${SPARSE_FOLDER_N})
	do
		eval _folder='$SPARSE_FOLDER_'${_idx}
		if [ -z "${_folder}" ]
		then
			break
		fi

		mkdir -p /${3}/${_folder}
		echo "> syncing ${1}:${2}/${_folder}"
		${RSYNC} ${X} -zahH --delete -e "${SSH} -i '${IDENTITY_FILE}'" \
			${1}:${2}/${_folder}/ /${3}/${_folder}
	done
	echo ''
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
