#!/bin/sh

# get new svn revisions
echo '> syncing fli4l repository'
/usr/bin/svnsync sync file:///tank/backup/nettworks/svn/fli4l
echo ''

# get new svn revisions
echo '> syncing eisfair repository'
/usr/bin/svnsync sync file:///tank/backup/nettworks/svn/eisfair
echo ''

# get new svn revisions
echo '> syncing org repository'
/usr/bin/svnsync sync file:///tank/backup/nettworks/svn/org
echo ''

# handle zfs snapshots
if [ "$(date +%d)" = "13" ]
then    
        echo '> creating zfs snapshot'
        /usr/bin/sudo -n /usr/sbin/zfSnap -v -s -S -a 1y tank/backup/nettworks/svn
        echo ''
fi      
