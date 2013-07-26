#!/bin/bash

# ------------------------------------------------------------------------------
#  backup-db.sh -d DATABASE_NAME -b BACKUP_FOLDER_PATH -v -s
# ------------------------------------------------------------------------------





usage()
{
cat << EOF

--------------------------------------------------------------------------------
usage: $0 options
--------------------------------------------------------------------------------
This script backs up the specified mysql database.

OPTIONS:
   -h      Show this message
   -d      Database name       (required)
   -b      Backup folder path  (optional)    Defaults to pwd.
   -v      Verbose
   -s      Silent
EOF
}





DATABASE_NAME=
BACKUP_FOLDER_PATH=
VERBOSE=0
SILENT=0
while getopts ":hd:b:vs" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             DATABASE_NAME=$OPTARG
             ;;
         b)
             BACKUP_FOLDER_PATH=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
         s)
             SILENT=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $DATABASE_NAME ]]
then
    usage
    exit 1
fi

# kill verbose if silent exists
if [[ $SILENT -eq 1 ]]; then
    VERBOSE=0
fi


if [[ $VERBOSE -eq 1 ]]; then
    echo
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo '##### BACKUP DB SCRIPT #####'
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi





if [ ${server_maintenance_conf-_} != 'loaded' ]; then
    if [[ $VERBOSE -eq 1 ]]; then
        echo "> this script expects some global vars, loading the conf file -> [$(dirname $0)/server-maintenance.conf]"
        echo
    fi
    source $(dirname $0)/server-maintenance.conf
fi





if [[ $BACKUP_FOLDER_PATH == '' ]]; then
    BACKUP_FOLDER_PATH=`pwd`
fi

if [[ $VERBOSE -eq 1 ]]; then
    echo '----- Script Args ----------------------------------------------------------------------------------'
    echo '$DATABASE_NAME      ->' $DATABASE_NAME
    echo '$BACKUP_FOLDER_PATH ->' $BACKUP_FOLDER_PATH
    echo '----------------------------------------------------------------------------------------------------'
    echo
fi

# find the last char
total_chars=${#BACKUP_FOLDER_PATH}
almost_all_chars=$(($total_chars-1))
last_char=${BACKUP_FOLDER_PATH:almost_all_chars:1}

# add a slash to end of path if it doesnt have one
if [ $last_char != '/' ]; then
    BACKUP_FOLDER_PATH=$BACKUP_FOLDER_PATH'/'    
fi

if [[ $SILENT -eq 0 ]]; then    
    echo
    echo ">>> BACKING UP DB         -> $DATABASE_NAME"
fi

db_backup_filename=$backupdate.$db_label.$DATABASE_NAME.sql$compression_ending

db_backup_path=$BACKUP_FOLDER_PATH$db_backup_filename;

# backup
# $mysqldump_command -u$mysql_backup_user -p$mysql_backup_pass --databases $DATABASE_NAME | $db_compression_flag > $db_backup_path;
# $mysqldump_command -u$mysql_backup_user --databases $DATABASE_NAME | $db_compression_flag > $db_backup_path;

if [[ $SILENT -eq 0 ]]; then
    echo '>>> BACKUP DONE, LOCATION -> '$db_backup_path
    echo
fi

if [[ $VERBOSE -eq 1 ]]; then
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi




