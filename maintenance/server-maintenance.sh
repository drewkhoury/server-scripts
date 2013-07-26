#!/bin/bash

#
#   Created by Drew Khoury - Radical Systems - Version 0.2 Beta
#
#   Warning: Use at your own risk!
#
#   Overview:
#       Server/Script level features are controlled through the "EDITABLE VARIABLES" section at start of this script
#       Website level features are controlled through website configuration files that live in $home_dir/$user/ 
#
#   Walkthrough of Main Features:
#       Daily
#           Database Backup (to local database folder)
#           Table Optimisation for Databases & Flush
#           Backup User Directory (excluding the local backup folder, this is not the movie inception)
#           Clear old files in backup and database folders
#           Reset Permissions for site
#       Monthly (1st of the month)
#           Move Backup Offisite
#           Clear old Offsite Backups (keep first ever backup, all jan backups (yearly) and the latest 3 backups)
#
#   Instructions:
#       Run as a cron daily, at a quiet time, ie 3am.
#       As a minimum you will need to have
#           1) the right folder structure in place /home/drew/web/www /homedrew/backups /home/drew/databases etc
#           2) individual website config files /home/drew/website.ini
#           3) configure at least a few editable variables $home_dir $mysql_backup_user $mysql_backup_pass $mysql_command $mysqlcheck_command $mysqldump_command
#           4) install and configure s3cmd (either through apt-get or by placing files somewhere) and configure the following editable variables $s3_bin and $s3_url
#
#   Assumptions:
#       user folders are located in a single directory, under the home directory
#       website.ini files live in $home_dir/$user/ eg /home/drew/website.ini
#       mysql user has reload privileges (for flush)
#       s3cmd installed and configured (for offsite backup functionaility) & AWS-S3 Account handy
#
#   Notes:
#       website.ini can take variables, those are expected to be defined in the script (a working example of this is the permissions section)
#       script should be run daily, monthly actions are preformed on the 1st of the month
#       due to special monthly logic, sometimes an extra weekly backup is made (to make sure a weekly backup always exists on the 1st of the month, as well as the regular weekly backup on sat)
#    
#   Example website.ini
#
#       [backup]
#       wcnf_backup=daily                                   # never, daily, weekly, monthly
#       wcnf_offsite_backups=monthly                        # never, monthly
#       wcnf_delete_backups_older_then_this_days=30         # 1, 7, 30 (default=30, and if illegal var supplied will revert to a value of 30)
#    
#       [database]
#       wcnf_db_name=joomla
#       wcnf_db_backup_freq=daily                           # never, daily, weekly, monthly
#       wcnf_db_optimise_freq=daily                         # never, daily, weekly, monthly
#    
#       [permissions]
#       wcnf_files_to_make_writeable=www/sitemap.xml www/file2.html www/file3.html
#       wcnf_folders_to_make_writeable=$permissions_joomla_images $permissions_joomla_docman
#       wcnf_files_to_make_not_writeable=www/conf.php www/file.html
#       wcnf_owner=drew
#       wcnf_group=www-data
#
#   Roadmap:
#       @todo - logging (to /log/var) with seperate logs for things like permissions which will probably have lots of output if put together
#       @todo - breakdown script into disctinct functions, that can be used independently of the script, in a modular fashion ie server-maintenance.sh backup drew
#       @todo - allow multiple databases to be defined for a site
#       @todo - potentially allow multiple sites to be defined per user
#       @todo - need an expert to outline full implications of the flush command
#
#
#   v 0.2 changes
#       - assumes no mysql password is required
#       - fixed issues with permissions when some vars are left empty
#       - added date vars to output
#       - fixed typos
#       - added logic for web folder, which contains all the websites files, with the only the www folder publically accessable
#       - added include for main config
#       - renamed basic to backup in config









# ------------------------------------------------------------------------------
#  server-maintenance.sh -v -s
# ------------------------------------------------------------------------------





usage()
{
cat << EOF

--------------------------------------------------------------------------------
usage: $0 options
--------------------------------------------------------------------------------
This script executes a number of server administration tasks.

OPTIONS:
   -h      Show this message
   -v      Verbose
   -s      Silent
EOF
}





VERBOSE=0
SILENT=0
while getopts ":hd:b:vs" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
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

# kill verbose if silent exists
if [[ $SILENT -eq 1 ]]; then
    VERBOSE=0
fi

# set silent and verbose flags for scripts
verbose_flag=
silent_flag=

if [[ $VERBOSE -eq 1 ]]; then
    verbose_flag='-v'
fi

if [[ $SILENT -eq 1 ]]; then
    silent_flag='-s'
fi





if [[ $VERBOSE -eq 1 ]]; then
    clear
    
    # TIME LOG =====================================================================
    echo
    echo
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '------------------------------ SCRIPT STARTED ----------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo
    echo `date`
    echo
    echo
fi





# CONFIG =======================================================================

source $(dirname $0)/server-maintenance.conf





# FUNCTIONS ====================================================================

# ini parser function
cfg.parser () {
    IFS=$'\n' && ini=( $(<$1) )              # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result
}





# ==============================================================================
# START SCRIPT =================================================================
# ==============================================================================

# iterate through the home directory
for user in $( ls -1 $home_dir ); do

    # set the website config file path and name
    website_config_file=$home_dir"/$user/$website_config_name"
    
    # test to see if the config file exists
    if [ -f $website_config_file ]; then

        if [[ $VERBOSE -eq 1 ]]; then
            echo '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
            echo '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
            echo "-----> WALKING THROUGH USER [$user]"
            echo '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
            echo '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
            echo ''
        fi
        
        # load vars from website config
        cfg.parser $website_config_file
        cfg.section.backup
        cfg.section.database
     
     
     
     
     
        # ======================================================================
        # BACKUP DB ============================================================
        # ======================================================================
        
        # assume we dont need to backup, until the config tells us otherwise
        do_we_need_to_backup_db=0
        
        # do we need to backup today?
        case $wcnf_db_backup_freq in
            'never')
            ;;
            'daily')
                do_we_need_to_backup_db=1
            ;;
            'weekly')
                # always backup on saturdays (they should be quiet)
                if [ $day_of_week -eq 6 ]; then
                do_we_need_to_backup_db=1
                fi
              
                # if today is 1st of the month, backup
                # we ALWAYS need a backup on the 1st for offsite backup logic
                if [ $day_of_month -eq 1 ]; then
                do_we_need_to_backup_db=1
                fi
            ;;
            'monthly')
                # if today is the 1st of the month backup
                if [ $day_of_month -eq 1 ]; then
                  do_we_need_to_backup_db=1
                fi
            ;;
        esac
        
        # backup if we need to
        if [ $do_we_need_to_backup_db -eq 1 ]; then
            
            $(dirname $0)/scripts/backup-db.sh -d $wcnf_db_name -b $home_dir/$user/$db_backup_folder $verbose_flag  $silent_flag
            
        else
            if [[ $SILENT -eq 0 ]]; then
                echo '>>> I SEE NO REASON TO BACKUP DB TODAY'
                echo
            fi
        fi
        
        
        
        
        
        # ======================================================================     
        # OPTIMISE DB TABLES ===================================================
        # ======================================================================
        
        # assume we dont need to optimise, until the config tells us otherwise
        do_we_need_to_optimise_db=0
        
        # do we need to optimise today?
        case $wcnf_db_optimise_freq in
            'never')
            ;;
            'daily')
                do_we_need_to_optimise_db=1
            ;;
            'weekly')
                # always backup on saturdays (they should be quiet)
                if [ $day_of_week -eq 6 ]; then
                    do_we_need_to_optimise_db=1
                fi
                
                # if today is 1st of the month, backup
                # we ALWAYS need a backup on the 1st for offsite backup logic
                if [ $day_of_month -eq 1 ]; then
                    do_we_need_to_optimise_db=1
                fi
            ;;
            'monthly')
                # if today is the 1st of the month backup
                if [ $day_of_month -eq 1 ]; then
                    do_we_need_to_optimise_db=1
                fi
            ;;
        esac
        
        # optimise if we need to
        if [ $do_we_need_to_optimise_db -eq 1 ]; then
            
            $(dirname $0)/scripts/optimise-db.sh -d $wcnf_db_name $verbose_flag  $silent_flag           
            
        else
            if [[ $SILENT -eq 0 ]]; then
                echo '>>> I SEE NO REASON TO OPTIMISE DB TODAY'
                echo
            fi
        fi        
        
        
        
        
        

        
        # ======================================================================        
        # BACKUP FILES =========================================================
        # ======================================================================
        
        # assume we dont need to backup, until the config tells us otherwise
        do_we_need_to_backup=0
        
        # do we need to backup today?
        case $wcnf_backup in
            'never')
            ;;
            'daily')
                do_we_need_to_backup=1
            ;;
            'weekly')
                # always backup on saturdays (they should be quiet)
                if [ $day_of_week -eq 6 ]; then
                    do_we_need_to_backup=1
                fi
              
                # if today is 1st of the month backup,
                # we ALWAYS need a backup on the 1st for offsite backup logic
                if [ $day_of_month -eq 1 ]; then
                    do_we_need_to_backup=1
                fi
            ;;
            'monthly')
                # if today is the 1st of the month backup
                if [ $day_of_month -eq 1 ]; then
                    do_we_need_to_backup=1
                fi
            ;;
        esac
        
        # backup if we need to
        if [ $do_we_need_to_backup -eq 1 ]; then
            
            $(dirname $0)/scripts/backup-files.sh -b ./$user -e $backup_folder -t ./$user/$backup_folder -f $home_dir $verbose_flag  $silent_flag
            
            #cd $home_dir
            #tar cf$compression_flag $home_dir/$user/$backup_folder/$backupdate.$files_label.$user'.tar'$compression_ending --exclude="$backup_folder" $home_dir/$user            
            
        else
            if [[ $SILENT -eq 0 ]]; then
                echo '>>> I SEE NO REASON TO BACKUP TODAY'
                echo
            fi
        fi


        
        
        
        # ======================================================================        
        # CLEANUP FILES ========================================================
        # ======================================================================    
      
        # if the var is anything except 1,7,30...set it to 30 (the default value)
        case $delete_backups_older_then_this_days in
        1)
          ;;
        7)
          ;;
        30)
          ;;
        *)
            delete_backups_older_then_this_days=30
          ;;
        esac
        
        echo '>>> DELETING BACKUP FILES OLDER THEN '$delete_backups_older_then_this_days' DAYS'
        
        # files
        #find $home_dir/$user/$backup_folder -mtime +1 -exec rm -rf {} \;
        
        echo '>>> DELETING DBS OLDER THEN 7 DAYS'
        
        # dbs
        #find $home_dir/$user/$db_backup_folder -mtime +7 -exec rm -rf {} \;
        
        echo '>>> DONE DELETING FILES'
        echo
     
     
        
        
        # set-permissions.sh     
     
        
        
    fi
done




# offsite-backups.sh





if [[ $VERBOSE -eq 1 ]]; then
    echo
    echo
    echo `date`
    echo
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '------------------------------ SCRIPT FINISHED ---------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo '--------------------------------------------------------------------------'
    echo
    echo
fi
