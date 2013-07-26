#!/bin/bash

# v 1.0










usage()
{
cat << EOF

--------------------------------------------------------------------------------
usage: $0 options
--------------------------------------------------------------------------------
This script adds a user.

OPTIONS:
   -h      Show this message
   -d      Domain Name
   -v      Verbose
   -s      Silent

EXAMPLE:
    add-account.sh -d DOMAIN_NAME -v
    
EOF
}





DOMAIN_NAME=
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
             DOMAIN_NAME=$OPTARG
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





if [[ -z $DOMAIN_NAME ]]
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
    echo '##### ADD HOSTING/USER ACCOUNT SCRIPT #####'
    echo '----------------------------------------------------------------------------------------------------------------------------------'
    echo
fi





if [[ $VERBOSE -eq 1 ]]; then
    echo '----- Script Args ----------------------------------------------------------------------------------'
    echo '$DOMAIN_NAME   ->' $DOMAIN_NAME    
    echo '----------------------------------------------------------------------------------------------------'
    echo
fi





# get the primary ip
function system_primary_ip {
    # returns the primary IP assigned to eth0
    echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
}

# generate a username
function generate_username {

    # make sure its only alphanum
    DOMAIN_NAME_ALPHANUM="$(echo $DOMAIN_NAME | sed -e 's/[^[:alnum:]]//g')"

    # create username part
    USER_NAME_PART=${DOMAIN_NAME_ALPHANUM:0:4}
    
    # create random number 
    FLOOR=999
    RANGE=10000
    
    # Combine above two techniques to retrieve random number between two limits.
    number=0   #initialize
    while [ "$number" -le $FLOOR ]
    do
      number=$RANDOM
      let "number %= $RANGE"  # Scales $number down within $RANGE.
    done
    
    # full username
    FULL_USERNAME=$USER_NAME_PART$number
    
}

# check if username exists
function check_username {

    USERNAME_CHECK_FAILED=false

    for f in `cat /etc/passwd | cut -d: -f1`; do
        if [[ $FULL_USERNAME == $f ]]; then
            USERNAME_CHECK_FAILED=true
            generate_username
            if [[ $VERBOSE -eq 1 ]]; then
                echo '>>> Username already exists! I will have to choose another to avoid a clash.'
            fi
        fi
    done
    
    if [[ $USERNAME_CHECK_FAILED == false ]]; then
        UNIQUE_USERNAME=true
    fi
    
}

# http://evan.borgstrom.ca/post/538694787/a-better-bash-random-password-generator
randompass() {
        MATRIX="HpZld&xsG47f0)W^9gNa!)LR(TQjh&UwnvP(tD5eAzr6k@E&y(umB3^@!K^cbOCV)SFJoYi2q@MIX8!1"
        PASS=""
        n=1
        i=1
        [ -z "$1" ] && length=8 || length=$1
        [ -z "$2" ] && num=1 || num=$2
        while [ ${i} -le $num ]; do
                while [ ${n} -le $length ]; do
                        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
                        n=$(($n + 1))
                done
                echo $PASS
                n=1
                PASS=""
                i=$(($i + 1))
        done
}



function add_user {

    # create a user that CAN SFTP but CANNOT see anything outside of ~ and CANNOT gain access to a shell
    
    # assume this stuff has been done
    # cd /etc/skel/
    # touch file-from-skel
    # addgroup sftp
    # sshd config = Subsystem sftp /usr/lib/openssh/sftp-server
    
    USER_NAME=$FULL_USERNAME
    USER_PASS=`randompass 32`
    USER_HOME=/data/$USER_NAME
    PRIMARY_IP_ADDRESS=`system_primary_ip`
    
    if [[ $SILENT -eq 0 ]]; then
        echo
        echo '>>> Adding user -> '$USER_NAME
        echo '>>> Password    -> '$USER_PASS
        echo '>>> Home Dir    -> '$USER_HOME
        echo
    fi
    
    useradd -c 'created by add-account.sh' -d $USER_HOME -m -G sftp -s /sbin/nologin $USER_NAME
    
    # limit permissions for the user
    chown -R root:root $USER_HOME
    chown root:$USER_NAME $USER_HOME/web
    chown -R $USER_NAME:$USER_NAME $USER_HOME/web/www
    
    # lock down auth key, allow access from main admin
    chown $USER_NAME:$USER_NAME $USER_HOME/.ssh/authorized_keys
    cat /home/superdrew/.ssh/authorized_keys >> /data/$USER_NAME/.ssh/authorized_keys

    echo "$USER:$USER_PASS" | chpasswd
    
    echo "[domain]
domain=$DOMAIN_NAME

[backup]
wcnf_backup=daily
wcnf_offsite_backups=never
wcnf_delete_backups_older_then_this_days=30

[database]
wcnf_db_name=
wcnf_db_backup_freq=never
wcnf_db_optimise_freq=never

[permissions]
wcnf_files_to_make_writeable=
wcnf_folders_to_make_writeable=
wcnf_files_to_make_not_writeable=
wcnf_owner=$USER_NAME
wcnf_group=www-data

" > $USER_HOME/website.ini

echo "

# force everything to www
server {
  listen          $PRIMARY_IP_ADDRESS:80;
  server_name     $DOMAIN_NAME *.$DOMAIN_NAME;
  rewrite ^       http://www.$DOMAIN_NAME\$request_uri? permanent;
}

# www
server {
  listen          $PRIMARY_IP_ADDRESS:80;
  server_name     www.$DOMAIN_NAME;

  access_log  /var/log/nginx-global-access.log combinedplus;
  access_log  $USER_HOME/logs/nginx-$DOMAIN_NAME.access.log  combinedplus;
  error_log   $USER_HOME/logs/nginx-$DOMAIN_NAME.error.log warn;

  root   $USER_HOME/web/www;

  location ~ \.php$ {
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include        /rs/confs/nginx/fastcgi_params;
  }
}


#server {
#
#  listen      $PRIMARY_IP_ADDRESS:443;
#  server_name $DOMAIN_NAME;
#
#  access_log  /var/log/nginx-global-access.log combinedplus;
#  access_log  $USER_HOME/logs/nginx-$DOMAIN_NAME.access.log  combinedplus;
#  error_log   $USER_HOME/logs/nginx-$DOMAIN_NAME.error.log warn;
# 
#  root   $USER_HOME/web/www;
#   
#  location / {
#    auth_basic            'Authorised Users Only. ALL INFORMATION LOGGED.';
#    auth_basic_user_file  /rs/passwords/.htpasswd;
#  }
#   
#  ssl                 on;
#  ssl_certificate     /rs/ssl/ssl.crt;
#  ssl_certificate_key /rs/ssl/ssl.key;
#  ssl_session_timeout  5m;
#  ssl_protocols  SSLv2 SSLv3 TLSv1;
#  ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
#  ssl_prefer_server_ciphers   on;
#
#  location ~ \.php$ {
#    fastcgi_param HTTPS on;
#    fastcgi_pass   127.0.0.1:9000;
#    fastcgi_index  index.php;
#    fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
#    include        /rs/confs/nginx/fastcgi_params;
#  }
#
#}

" > $USER_HOME/nginx-$USER_NAME.conf

# add line in nginx conf
echo "include $USER_HOME/nginx-$USER_NAME.conf;" >> /rs/confs/nginx-sites.conf 

# make available to superdrew for easy editing
chown superdrew:root /data/$USER_NAME/nginx-$USER_NAME.conf
ln -s /data/$USER_NAME/nginx-$USER_NAME.conf     /home/superdrew/nginx-$USER_NAME.conf

# reload nginx config
nginx -t
nginx -s reload


}






# set unique test to false to begin
UNIQUE_USERNAME=false

# create a username
generate_username

# keep checking/generating username until its unique
while [ $UNIQUE_USERNAME == false ]
do
    check_username
done





# add a new user
add_user









