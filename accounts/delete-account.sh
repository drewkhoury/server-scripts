#!/bin/bash

# v 1.0










usage()
{
cat << EOF

--------------------------------------------------------------------------------
usage: $0 options
--------------------------------------------------------------------------------
This script deletes a user.

OPTIONS:
   -h      Show this message
   -u      Username
   -c      Confirm you REALLY want to do this
   -v      Verbose
   -s      Silent

EXAMPLE:
   delete-account.sh -u USER_NAME -c -v

EOF
}




USER_NAME=
CONFIRM=
VERBOSE=0
SILENT=0
while getopts ":hu:cvs" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         u)
             USER_NAME=$OPTARG
             ;;
         c)
             CONFIRM=1
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





if [[ -z $USER_NAME || -z $CONFIRM ]]
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
    echo '##### DELETE HOSTING/USER ACCOUNT SCRIPT #####'
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi





if [[ $VERBOSE -eq 1 ]]; then
    echo '----- Script Args ----------------------------------------------------------------------------------'
    echo '$USER_NAME   ->' $USER_NAME    
    echo '----------------------------------------------------------------------------------------------------'
    echo
fi





USERNAME_EXISTS=false

for f in `cat /etc/passwd | cut -d: -f1`; do
    if [[ $USER_NAME == $f ]]; then
        USERNAME_EXISTS=true
    fi
done


if [[ $USERNAME_EXISTS == true ]]; then


    # check the userid, we can only remove range 1000-29999
    if [[ `id -u $USER_NAME` -lt 1000 || `id -u $USER_NAME` -gt 29999 ]]; then
        
        if [[ $SILENT -eq 0 ]]; then
            echo '>>> This is not a regular user acount. I cannot delete special accounts.'
            echo
        fi
        
        exit
        
    fi
     
    # check the comments, we can only remove what we created 'created by add-account.sh'
    if [[ `cat /etc/passwd | grep $USER_NAME: | cut -d: -f5` != 'created by add-account.sh' ]]; then
        
         if [[ $SILENT -eq 0 ]]; then
            echo '>>> This account was not created by the add-account script. I cannot delete accounts that I did not make.'
            echo
        fi
        
        exit
        
    fi

    if [[ $SILENT -eq 0 ]]; then
        echo
        echo '>>> Deleting user -> '$USER_NAME
        echo
    fi
    
    # delete the user
    userdel -r $USER_NAME
    
    if [[ $SILENT -eq 0 ]]; then
        echo
        echo '>>> Deleting user home folder -> '/data/$USER_NAME
        echo
    fi
    
    # delete the home folder
    rm -rf /data/$USER_NAME
    
    # delete the nginx include
    sed -i "/$USER_NAME/d" /rs/confs/nginx-sites.conf

else
    if [[ $SILENT -eq 0 ]]; then
        echo '>>> Username does not exist. I cannot delete something that isnt there.'
        echo
    fi 
fi










