server-scripts
==============

Scripts for setup, maintenance &amp; account management of a typical web server


# Standard Server Setup - Linode Stack Script
#
# Note: This script can be run as a bash script too (with slight modifications, 
# the disk partitioning is currently linode specific)
# 
# By drew <support@radicalsystems.net>
#
# --- Legend --- ###############################################################
#
# SCRIPT SETUP
# ------------------------------------------------------------------------------
#   Variables used by linode to kick off a stackscript.
#   Functions used throught the script.
#   Setup correct timezone
#   Create the system's base folders.
#   Create an install log and note what packages were originally installed.
#     
# AUTHENTICATION SETUP
# ------------------------------------------------------------------------------
#   Configure ssh & sudo.
#     
# OS SETUP
# ------------------------------------------------------------------------------
#   Set the hostname, download/install latest packages, 
#   install a few basic packages. Set language paramaters & locale.
#   Install other packages we will need for the script.
#     
#
# FIREWALL SETUP
# ------------------------------------------------------------------------------
#   Install & configure firehol.
#   Creates the iptable rules based on a firehol config file.
#   Proper Service that gets started when the interface comes up.
#
# CONFIGURE DATA DISK
# ------------------------------------------------------------------------------
#   Configures a disk that cant run executable scripts (for security reasons)
#   to be used as the www drive.
#     
# WEB DEV - PREPARE
# ------------------------------------------------------------------------------
#   Download & Unpack the sources we need for our web server (nginx, php etc)
#   Configure nginx so it doesn't show its servername to the public
#     
# WEB DEV - INSTALL
# ------------------------------------------------------------------------------
#   Build nginx, php etc. Install & Tune mysql
#     
# WEB DEV - CONFIGURE - NGINX
# ------------------------------------------------------------------------------
#   Nginx Config, Init Script
#     
# WEB DEV - CONFIGURE - PHP
# ------------------------------------------------------------------------------
#   Configure PHP, Add extnetions (memcache, apc, suhosin) & Configure APC.
#   Configure PHP-FPM & PHP-FPM init script.
#     
# WEB DEV - CONFIGURE - SSL
# ------------------------------------------------------------------------------
#   Configures a Self Signed SSL for dev purposes
# 
# FINAL BITS
# ------------------------------------------------------------------------------
#   Create a dev folder for phpmyadmin/phpinfo/apc.
#   Create a /etc/rc.local script that will run on reboot (this will make sure
#       the data disk is properly mounted on next boot).
#   Note the installed packages, script end time, and clean the sources folder.
#   Leave a token so we know the script has completed (ie dont run again)
#
# --- Legend --- ###############################################################







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
