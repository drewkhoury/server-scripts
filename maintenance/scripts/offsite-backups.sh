# ==============================================================================
# OFFSITE BACKUPS ==============================================================
# ==============================================================================

# only upload offsite once a month
if [ $day_of_month -eq 1 ]; then

    # start iterating through the home directory
    for user in $( ls -1 $home_dir ); do
        
        # set the ini file path and name
        website_config_file=$home_dir/$user/$website_config_name
        
        # test to see if the ini file exists
        if [ -f $website_config_file ]; then
            
            # load vars from website config
            cfg.parser $website_config_file
            cfg.section.basic
            
            if [ $wcnf_offsite_backups = 'monthly' ]; then
                
                
                
                
                
                # ==============================================================        
                # OFFSITE BACKUP - FILES =======================================
                # ==============================================================
                
                # vars
                file_backup_exists=0
                backup_dir=$home_dir/$user/$backup_folder
                backup_dir_size=${#backup_dir}
                
                # loop through and find/upload backups for today (1st)
                for i in $(find $backup_dir -name $backupdate"\.$files_label\.*"); do
                    # strip the path and leave the name
                    filename_only=${i:$backup_dir_size+1}
                    
                    echo ">>> UPLOADING BACKUP"
                    echo
                    
                    # upload a complete backup offsite (from today), eg to amazon
                    $s3_bin put $i $s3_url/$user/$filename_only;
                    file_backup_exists=1
                    
                    echo
                    echo ">>> BACKUP DONE UPLOADING"
                    
                    echo
                    
                done
                
                
                
                
                
                # if there is no backup for today, report error but continue
                if [ $file_backup_exists -eq 0 ]; then
                    echo '>>> this is bad for '$user
                fi
                
                
                
                
                
                # ==============================================================        
                # REMOVE OLD OFFSITE BACKUPS ===================================
                # ==============================================================               
                
                echo '>>> CHECKING FOR OLD OFFSITE BACKUPS TO REMOVE'
                echo
                
                # vars                
                count=0
                total_number_of_files=`$s3_bin ls $s3_url/$user/ | cut -d "/" -f 5 | grep '.tar.bz2' | wc -l`
                
                # example of the cut...
                # 2011-10-25 01:13    215948   s3://s3-url/drew/2011-10-25.files.drew.tar.bz2
                # (2011-10-25 01:13    215948   s3:)=1 / ()=2 / (s3-url)=3 / (drew)=4 / (2011-10-25.files.drew.tar.bz2)=5
                for line in $( $s3_bin ls $s3_url/$user/ | cut -d "/" -f 5 | grep '.tar.bz2'); do
                    
                    # vars
                    ((count++))
                    
                    #backup_file_day=${line:8:2}              
                    backup_file_month=${line:5:2}
                    
                    second_last_line=$(($total_number_of_files-1))
                    third_list_line=$(($total_number_of_files-2))
                    
                    skip=0
                    
                    # very first backup ever
                    if [ $count -eq 1 ]; then
                        skip=1
                    # yearly backups
                    elif [ $backup_file_month = '01' ]; then
                        skip=1
                    # recent
                    elif [ $count -eq ${total_number_of_files} ]; then
                        skip=1
                    # recent
                    elif [ $count -eq $second_last_line ]; then
                        skip=1
                    # recent
                    elif [ $count -eq $third_list_line ]; then
                        skip=1              
                    fi
                    
                    # echo $line "($skip)"
                    
                    # if its not an important backup (identified above) then lets delete it and save some space
                    if [ $skip -eq 0 ]; then
                        echo "   Removing... "$s3_url/$user/$line
                        $s3_bin del $s3_url/$user/$line
                        echo
                    fi
                    
                done
                
                echo
                echo '>>> DONE REMOVING OLD OFFSITE BACKUPS'
                
                
                
                
                # update new list of offsite backup files in account.info
                #
                #
                #
                #
                #
                
                
                
                
                
            fi
           
            
            
        fi
    done

fi