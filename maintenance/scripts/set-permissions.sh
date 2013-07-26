     
        # ======================================================================        
        # PERMISSIONS ==========================================================
        # ======================================================================
        
        # load vars from website config
        #cfg.parser $website_config_file
        cfg.section.permissions
        
        #################### VARIABLES & FUNCTIONS #############################
        
        # web directory
        web_root=$home_dir/$user/$web_folder
        
        # set the user and group (in theory we could use the $user var or we could hardocde via config)
        files_owner=$wcnf_owner
        files_group=$wcnf_group
        
        function make_full_paths {
            
            # only do something if the string isn't empty
            if [ -n "$1" ]; then
                
                # add space to the start of string
                paths=' '$1
                
                # replace each space with the full www-root
                paths=${paths// / $web_root/};
                
            fi
        }
        
        make_full_paths $wcnf_files_to_make_writeable;
        files_to_make_writeable=$paths
        
        make_full_paths $wcnf_folders_to_make_writeable;
        folders_to_make_writeable=$paths
        
        make_full_paths $wcnf_files_to_make_not_writeable;
        files_to_make_not_writeable=$paths
        
        # merge lists
        exclude_list=${files_to_make_writeable}${folders_to_make_writeable}${files_to_make_not_writeable}
        
        # only if exclude_list isn't empty
        if [ -n "$exclude_list" ]; then
            
            # removing first char, its an unwanted space
            exclude_list=${exclude_list:1}
            
            # replace all spaces with a chain of exlcude paths
            exclude_list=${exclude_list// /' -prune -or -path '};
            
            # the exclude path syntax for start and end of string
            exclude_list='-path '${exclude_list}' -prune -or ';
            
        fi
       
       
        #################### SET THE RIGHT PERMISSIONS #########################
        
        function run_command {
            echo "# ---[$1]----------------------------------------------------"
            echo $2
            echo
            eval $2
            echo
            
        }
        
        run_command 'set owner and group'   "chown -R $files_owner:$files_group $web_root"
        
        run_command 'lock (most) folders'  "find $web_root ${exclude_list} -type d -exec chmod 755 {} \;"
        run_command 'lock (most) files'     "find $web_root ${exclude_list} -type f -exec chmod 644 {} \;"
        
        if [ -n "${files_to_make_not_writeable:1}" ]; then
            run_command 'lock files (specific)' "chmod 440 ${files_to_make_not_writeable:1};"
        fi
        
        for i in $( echo $folders_to_make_writeable ); do
            if [ -d $i ]; then
                run_command 'open folders (specific)' "find $i -type d -exec chmod 1777 {} \;"
            fi
        done
       
        if [ -n "${files_to_make_writeable:1}" ]; then
            run_command 'open files (specific)' "chmod 777 ${files_to_make_writeable:1};"
        fi
