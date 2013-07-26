#!/bin/bash

# ------------------------------------------------------------------------------
#  optimise-db.sh -d DATABASE_NAME -v -s
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
   -v      Verbose
   -s      Silent
EOF
}





DATABASE_NAME=
VERBOSE=0
SILENT=0
while getopts ":hd:vs" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             DATABASE_NAME=$OPTARG
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
    echo '##### OPTIMISE DB SCRIPT #####'
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





if [[ $VERBOSE -eq 1 ]]; then
    echo '----- Script Args ----------------------------------------------------------------------------------'
    echo '$DATABASE_NAME      ->' $DATABASE_NAME
    echo '----------------------------------------------------------------------------------------------------'
    echo
fi

if [[ $SILENT -eq 0 ]]; then    
    echo
    echo ">>> OPTIMISING DB TABLES FOR DB -> $DATABASE_NAME"
    echo '----------------------------------------------------------------------------------------------------'
fi

# optimise and flush the db
# $mysqlcheck_command --databases $db_name --optimize -u$mysql_backup_user -p$mysql_backup_pass;
$mysqlcheck_command --databases $DATABASE_NAME --optimize -u$mysql_backup_user;

# $mysql_command -u$mysql_backup_user -p$mysql_backup_pass $db_name -e'flush tables';
$mysql_command -u$mysql_backup_user $DATABASE_NAME -e'flush tables';

if [[ $SILENT -eq 0 ]]; then
    echo '----------------------------------------------------------------------------------------------------'
    echo '>>> OPTIMISING DONE'
    echo
fi

if [[ $VERBOSE -eq 1 ]]; then
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi




