#!/bin/bash

# ------------------------------------------------------------------------------
#  backup-files.sh -b BACKUP_DIRECTORY -e EXCLUDE_DIRECTORY -t PATH_TO_BACKUP_TO -f PATH_TO_BACKUP_FROM -n FILE_NAME-v -s
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
   -b      Backup Directory       (required)    The folder you want to back up.
   -e      Exclude Directory      (optional)    The folder you want to exlude from this backup.
   -p      Path to Backup to      (optional)    The folder where the final backup will be located. Defaults to pwd.
   -f      Path to Backup from    (optional)    The script will change to this folder just before the tar command is executed. Defaults to pwd.
   -n      File Name              (optional)    The script will try to generate a useful name for the file, however if File Name is supplied it will be used in part of the file name, eg 2012-02-10.files.MY_FILE_NAME.tar.bz2
   -v      Verbose
   -s      Silent
EOF
}





BACKUP_DIRECTORY=
EXCLUDE_DIRECTORY=
PATH_TO_BACKUP_TO=
BACKUP_FROM_THIS_DIR=
VERBOSE=0
SILENT=0
while getopts ":hb:e:t:f:vs" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BACKUP_DIRECTORY=$OPTARG
             ;;
         e)
             EXCLUDE_DIRECTORY=$OPTARG
             ;;
         t)
             PATH_TO_BACKUP_TO=$OPTARG
             ;;
         f)
             PATH_TO_BACKUP_FROM=$OPTARG
             ;;
         n)
             FILE_NAME=$OPTARG
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

if [[ -z $BACKUP_DIRECTORY ]]
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
    echo '##### BACKUP FILES SCRIPT #####'
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



if [[ $PATH_TO_BACKUP_TO == '' ]]; then
    PATH_TO_BACKUP_TO=`pwd`
fi

if [[ $PATH_TO_BACKUP_FROM == '' ]]; then
    PATH_TO_BACKUP_FROM=`pwd`
fi

if [[ $VERBOSE -eq 1 ]]; then
    echo '----- Script Args ----------------------------------------------------------------------------------'
    echo '$BACKUP_DIRECTORY       ->' $BACKUP_DIRECTORY
    echo '$EXCLUDE_DIRECTORY      ->' $EXCLUDE_DIRECTORY
    echo '$PATH_TO_BACKUP_TO      ->' $PATH_TO_BACKUP_TO
    echo '$PATH_TO_BACKUP_FROM    ->' $PATH_TO_BACKUP_FROM        
    echo '----------------------------------------------------------------------------------------------------'
    echo
fi

# try to use the backup dir as the file name
FILE_NAME=${BACKUP_DIRECTORY##*/}

# if the backup dir is empty its likely we are trying to backup the current dir, lets try that for a name
if [[ $FILE_NAME == '' ]]; then
    FILE_NAME=${PATH_TO_BACKUP_FROM##*/}
fi

# all hope is lost? lets try and seem smart
if [[ $FILE_NAME == '' ]]; then
    FILE_NAME='misc'
fi

BACKUP_LOCATION=$PATH_TO_BACKUP_TO/$backupdate.$files_label.$FILE_NAME'.tar'$compression_ending

# cd if its relative
cd $PATH_TO_BACKUP_FROM

if [[ $SILENT -eq 0 ]]; then    
    echo
    echo ">>> PRESENT DIRECTORY   -> `pwd`"
    echo ">>> BACKING UP FILES IN -> $BACKUP_DIRECTORY"
    echo ">>> COMMAND             -> tar cf$compression_flag $BACKUP_LOCATION --exclude=\"$EXCLUDE_DIRECTORY\" $BACKUP_DIRECTORY"
    echo '----------------------------------------------------------------------------------------------------'
fi





tar cf$compression_flag $BACKUP_LOCATION --exclude="$EXCLUDE_DIRECTORY" $BACKUP_DIRECTORY





if [[ $SILENT -eq 0 ]]; then
    echo '----------------------------------------------------------------------------------------------------'
    echo '>>> BACKUP DONE, LOCATION ->' $BACKUP_LOCATION
    echo
fi

if [[ $VERBOSE -eq 1 ]]; then
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi




