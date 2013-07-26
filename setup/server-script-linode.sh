#!/bin/bash

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





# ------------------------------------------------------------------------------
# --- TODOS --------------------------------------------------------------------
# ------------------------------------------------------------------------------

# log rotate
# make av run
# php-fpm changes to have the server-info var
# scripts to take into account server size (eg ram utilize)










# make sure this never runs more then once (this stackscript restarts to properly mount the new disk and this if is required to make sure it doesn't loop)
if [ ! -f /stack-script-complete ];
then










#############################################################################################################################################################################################################
# SCRIPT SETUP ##############################################################################################################################################################################################
#############################################################################################################################################################################################################

########## stackscript vars ##########

# <udf name="BASE_FOLDER" label="Base Folder Name" default="rs"/>

# <udf name="THE_API_KEY" label="Linode API Key" default="" />
# <udf name="THE_LINODE_MACHINE_ID" label="Linode Machine ID" default="" />
# <udf name="DATA_DRIVE_SIZE" label="Data Drive Size - MB" default="10000" />
# <udf name="DATA_DRIVE_LABEL" label="Data Drive Label (& Root Folder Name)" default="data" />

# <udf name="USER_NAME" label="Unprivileged User Account" default="" />
# <udf name="USER_PASSWORD" label="Unprivileged User Password" default=""/>
# <udf name="USER_SSHKEY" label="Public Key for User" />

# <udf name="SSHD_PORT" label="SSH Port" default="2222" />
# <udf name="SERVER_ADMIN_SECRET_PORT" label="SERVER ADMIN SECRET Port" default="9999" example="Used for server admin tasks, ie phpmyadmin,phpinfo,apc etc" />
# <udf name="WEBADMIN_PORT" label="WEB ADMIN Port" default="8888" example="Used for website admin tasks, ie Joomla, Magento etc" />

# <udf name="TRUSTED_IP" label="TRUSTED IP" default="" />

# <udf name="SSHD_GROUP" label="SSH Allowed Groups" default="sshusers" example="List of groups seperated by spaces" />

# <udf name="SUDO_USERGROUP" label="Usergroup to use for Admin Accounts" default="wheel" />
# <udf name="SUDO_PASSWORDLESS" label="Passwordless Sudo" oneof="Require Password,Do Not Require Password", default="Do Not Require Password" />

# <udf name="MYSQL_ROOT_PW" label="mySQL Root Password" default="" />

# <udf name="SSL_PASSWORD" label="SSL Certificate Password" default="" />

# <udf name="SSL_COMMON_NAME" label="SSL_COMMON_NAME" default="common_name" />
# <udf name="SSL_ORG" label="SSL_ORG" default="ssl_org" />
# <udf name="SSL_ORG_UNIT" label="SSL_ORG_UNIT" default="Web Security" />
# <udf name="SSL_CITY" label="SSL_CITY" default="Melbourne" />
# <udf name="SSL_STATE" label="SSL_STATE" default="Victoria" />
# <udf name="SSL_COUNTRY" label="SSL_COUNTRY" default="AU" />

# <udf name="AUTH_TEST_USER" label="AUTH_TEST_USER" default="user" />
# <udf name="AUTH_TEST_PASS" label="AUTH_TEST_PASS" default="pass" />

# <udf name="TIMEZONE" label="TIMEZONE" default="Australia/Melbourne" />





########## bash script vars ##########

# BASE_FOLDER="rs"

# THE_API_KEY=""
# THE_LINODE_MACHINE_ID"=""
# DATA_DRIVE_SIZE"="10000"
# DATA_DRIVE_LABEL="data"

# USER_NAME"=""
# USER_PASSWORD=""
# USER_SSHKEY=

# SSHD_PORT="2222"
# SERVER_ADMIN_SECRET_PORT="9999"
# WEBADMIN_PORT="8888"

# TRUSTED_IP=""

# SSHD_GROUP="sshusers"

# SUDO_USERGROUP="wheel"
# SUDO_PASSWORDLESS="Do Not Require Password"

# MYSQL_ROOT_PW=""

# SSL_PASSWORD=""

# SSL_COMMON_NAME="common_name"
# SSL_ORG="ssl_org"
# SSL_ORG_UNIT="Web Security"
# SSL_CITY="Melbourne"
# SSL_STATE="Victoria"
# SSL_COUNTRY="AU"

# AUTH_TEST_USER="user"
# AUTH_TEST_PASS="pass"

# TIMEZONE="Australia/Melbourne"




# functions

function system_primary_ip {
    # returns the primary IP assigned to eth0
    echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
}

function get_rdns {
    # calls host on an IP address and returns its reverse dns
    if [ ! -e /usr/bin/host ]; then
        aptitude -y install dnsutils > /dev/null
    fi
    echo $(host $1 | awk '/pointer/ {print $5}' | sed 's/\.$//')
}

function get_rdns_primary_ip {
    # returns the reverse dns of the primary IP assigned to this system
    echo $(get_rdns $(system_primary_ip))
}

# set the ip
PRIMARY_IP_ADDRESS=`system_primary_ip`





# make sure this script has the right binary paths (otherwise the script might fail, or produce different results when compared to a regular user running the same commands)
PATH=$PATH:/bin:/sbin:/usr/local/bin:/usr/local/sbin

# set the time      
echo ${TIMEZONE} > /etc/timezone
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime   # This sets the time

# create base folders
mkdir /${BASE_FOLDER}

mkdir /${BASE_FOLDER}/confs
mkdir /${BASE_FOLDER}/confs/nginx
touch /${BASE_FOLDER}/confs/nginx-sites.conf

mkdir /${BASE_FOLDER}/crons
mkdir /${BASE_FOLDER}/crons/hourly
mkdir /${BASE_FOLDER}/crons/daily
mkdir /${BASE_FOLDER}/crons/weekly
mkdir /${BASE_FOLDER}/crons/monthly

mkdir /${BASE_FOLDER}/logs
mkdir /${BASE_FOLDER}/sources
mkdir /${BASE_FOLDER}/msgs
mkdir /${BASE_FOLDER}/tmp
mkdir /${BASE_FOLDER}/ssl
mkdir /${BASE_FOLDER}/passwords
mkdir /${BASE_FOLDER}/scripts

# create symlinks for crons
ln -s /${BASE_FOLDER}/crons/hourly /etc/cron.hourly/hourly.custom
ln -s /${BASE_FOLDER}/crons/daily /etc/cron.daily/daily.custom
ln -s /${BASE_FOLDER}/crons/weekly /etc/cron.weekly/weekly.custom
ln -s /${BASE_FOLDER}/crons/monthly /etc/cron.monthly/monthly.custom

# marks the start of the script
echo Script Started: `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# what packages were originally installed
dpkg --get-selections > /${BASE_FOLDER}/msgs/software-inital.log










#############################################################################################################################################################################################################
# AUTHENTICATION SETUP ######################################################################################################################################################################################
#############################################################################################################################################################################################################
# Modified from http://www.linode.com/stackscripts/view/?StackScriptID=165
#############################################################################################################################################################################################################

# install sudo
apt-get install sudo

# make a copy of the original files
cp /etc/sudoers /etc/sudoers.original.log
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original.log

# create a tmp sudo config, edit it, then move it to /etc/sudoers
cp /etc/sudoers /etc/sudoers.tmp
chmod 0640 /etc/sudoers.tmp
test "${SUDO_PASSWORDLESS}" == "Do Not Require Password" && (echo "%`echo ${SUDO_USERGROUP} | tr '[:upper:]' '[:lower:]'` ALL = NOPASSWD: ALL" >> /etc/sudoers.tmp)
test "${SUDO_PASSWORDLESS}" == "Require Password" && (echo "%`echo ${SUDO_USERGROUP} | tr '[:upper:]' '[:lower:]'` ALL = (ALL) ALL" >> /etc/sudoers.tmp)
chmod 0440 /etc/sudoers.tmp
mv /etc/sudoers.tmp /etc/sudoers

# Configure SSHD
echo "# configuration file generated by linode stack script

# What ports, IPs and protocols we listen for
Port ${SSHD_PORT}

# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
#ListenAddress 0.0.0.0
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600
ServerKeyBits 768

# Logging
SyslogFacility AUTH
LogLevel DEBUG3

# Authentication:
LoginGraceTime 29
PermitRootLogin no
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

#MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of \"PermitRootLogin without-password\".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

AllowTcpForwarding no
ClientAliveCountMax 3
ClientAliveInterval 0
Compression delayed
MaxAuthTries 6
PermitTunnel no
PermitUserEnvironment no
UseDNS no

AllowGroups ${SSHD_GROUP} sftp

Subsystem sftp internal-sftp

Match Group sftp
    ForceCommand internal-sftp
    ChrootDirectory %h/web
    
" > /etc/ssh/sshd_config.tmp










chmod 0600 /etc/ssh/sshd_config.tmp
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config

# restart ssh service
/etc/init.d/ssh restart

echo 'SSH Configured & Resarted:' `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# Create Groups
groupadd ${SSHD_GROUP}
groupadd ${SUDO_USERGROUP}

# Create User & Add SSH Key
USER_NAME_LOWER=`echo ${USER_NAME} | tr '[:upper:]' '[:lower:]'`

useradd -m -s /bin/bash -G ${SSHD_GROUP},${SUDO_USERGROUP} ${USER_NAME_LOWER}
echo "${USER_NAME_LOWER}:${USER_PASSWORD}" | chpasswd

USER_HOME=`sed -n "s/${USER_NAME_LOWER}:x:[0-9]*:[0-9]*:[^:]*:\(.*\):.*/\1/p" < /etc/passwd`

sudo -u ${USER_NAME_LOWER} mkdir ${USER_HOME}/.ssh
echo "${USER_SSHKEY}" >> $USER_HOME/.ssh/authorized_keys
chmod 0600 $USER_HOME/.ssh/authorized_keys
chown ${USER_NAME_LOWER}:${USER_NAME_LOWER} $USER_HOME/.ssh/authorized_keys

# add stfp group, for regular users
addgroup sftp

# create a base skel for all users
rm /etc/skel/.bash_logout
rm /etc/skel/.bashrc
rm /etc/skel/.profile
mkdir /etc/skel/backups
mkdir /etc/skel/databases
mkdir /etc/skel/logs
mkdir /etc/skel/ssl
mkdir /etc/skel/web
mkdir /etc/skel/web/www
echo 'hello world' > /etc/skel/web/www/index.html
mkdir /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
chmod 400 /etc/skel/.ssh/authorized_keys










#############################################################################################################################################################################################################
# OS SETUP  #################################################################################################################################################################################################
#############################################################################################################################################################################################################

# setup hostname
get_rdns_primary_ip > /etc/hostname
/etc/init.d/hostname.sh start

# time log
echo 'Downloading latest packages (apt-get update):' `date` >> /${BASE_FOLDER}/msgs/install.log

# update the system with the latest packages (download them)
apt-get update

# upgrade the system with the downloaded packages (install them)
apt-get upgrade -y

# time log
echo 'Packages Installed (apt-get upgrade):' `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log





# set some language params
export LANGUAGE=en_AU.UTF-8
export LANG=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8

# make sure language params are applied for all users
echo '

# set some language params
export LANGUAGE=en_AU.UTF-8
export LANG=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8
' >> /etc/profile

# set the default locale to en_AU.UTF-8
echo '#  File generated by server-setup-script, could be edited by update-locale in the future
LANG=en_AU.UTF-8' > /etc/default/locale

# move the original locale.gen file somewhere safe
cp /etc/locale.gen /etc/locale.gen-original.log

# create a locale file with only en_AU locale available
echo '#  File generated by server-setup-script
en_AU.UTF-8 UTF-8' > /etc/locale.gen

# generate the AU locale
locale-gen





# install some basic software
apt-get install iptables wget unzip curl locate -y

# install antivirus
apt-get install clamav clamav-daemon -y

# time log
echo AV Installed: `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log





##################################################
# Install the typical packages needed for a regular server (need to seperate things required to build from source, and dependcies specific to nginx etc)
##################################################
# build-essential   : this package is required for building Debian packages.
# bison             : a general-purpose parser generator that converts a grammar description for an LALR(1) context-free grammar into a C program to parse that grammar.
# flex              : flex is a tool for generating scanners: programs which recognized lexical patterns in text. It reads the given input files for a description of a scanner to generate. The description is in the form of pairs of regular expressions and C code, called rules.
# patch             : Patch will take a patch file containing any of the four forms of difference listing produced by the diff program and apply those differences to an original file, producing a patched version.
# make              : GNU Make is an utility which controls the generation of executables and other target files of a program from the program's source files.
# gcc               : This is the GNU C compiler, a fairly portable optimizing compiler for C.
# autoconf          : The standard for FSF source packages. This is only useful if you write your own programs or if you extensively modify other people's programs.
##################################################
apt-get install build-essential bison flex patch make gcc autoconf -y



##################################################
# Install software related to webserver/nginx
##################################################
# openssl                   : This package contains the openssl binary and related tools. It is part of the OpenSSL implementation of SSL. You need it to perform certain cryptographic actions like: Creation of RSA, DH and DSA key parameters; Creation of X.509 certificates, CSRs and CRLs; Calculation of message digests; Encryption and decryption with ciphers; SSL/TLS client and server tests; Handling of S/MIME signed or encrypted mail.
# libapache-htpasswd-perl   : Manage Unix crypt-style password file. This module comes with a set of methods to use with htaccess password files. These files (and htaccess) are used to do Basic Authentication on a web server. The passwords file is a flat-file with login name and their associated crypted password. You can use this for non-Apache files if you wish, but it was written specifically for .htaccess style files.
# libssl-dev                : SSL development libraries, header files and documentation. libssl and libcrypto development libraries, header files and manpages. It is part of the OpenSSL implementation of SSL.
# zlib1g-dev                : compression library - development. zlib is a library implementing the deflate compression method found in gzip and PKZIP. This package includes the development support files.
##################################################
apt-get install openssl libapache-htpasswd-perl libssl-dev zlib1g-dev -y



##################################################
# Install software related to php and stuff
##################################################

########## crypto ##########
# mcrypt                      : mcrypt is a crypting program, intended to be replacement for the old unix crypt(1).
# libmcrypt-dev               : libmcrypt is the library which implements all the algorithms and modes found in mcrypt.
# libmhash-dev                : Library for cryptographic hashing and message authentication
# libmhash2                   : Library for cryptographic hashing and message authentication
# libmcrypt4                  : De-/Encryption Library. libmcrypt is the library which implements all the algorithms and modes found in mcrypt.
# libmhash-dev                : Library for cryptographic hashing and message authentication
apt-get install mcrypt libmcrypt-dev libmhash-dev libmhash2 libmcrypt4 libmhash-dev -y



########## html/xml/xslt ##########
#tidy                        : HTML syntax checker and reformatter
#libtidy-dev                 : HTML syntax checker and reformatter - development
#libxml2-dev                 : Install this package if you wish to develop your own programs using the GNOME XML library.
#libxml2                     : This package provides a library providing an extensive API to handle such XML data files.
#libxslt-dev                 : XSLT 1.0 processing library - development kit
apt-get install tidy libtidy-dev libxml2-dev libxml2 libxslt-dev -y



########## compression ##########
#libbz2-dev                  : high-quality block-sorting file compressor library - development
apt-get install libbz2-dev -y



########## ssl ##########
#libcurl4-openssl-dev        : These files (ie. includes, static library, manual pages) allow to build software which uses libcurl. SSL support is provided by OpenSSL.
#libcurl3-dev                : Development files and documentation for libcurl (OpenSSL)
apt-get install libcurl4-openssl-dev libcurl3-dev -y



## PostgreSQL
#libpq-dev                   : Header files and static library for compiling C programs to link with the libpq library in order to communicate with a PostgreSQL database backend.
#libpq5                      : libpq is a C library that enables user programs to communicate with the PostgreSQL database server. 
#
## images
#libjpeg62-dev               : Development files for the IJG JPEG library (version 6.2)
#libpng3-dev                 : PNG library - development
#libmagick9-dev              : image manipulation library - development files
#
## fonts
#libfreetype6-dev            : FreeType 2 font engine, development files. The FreeType project is a team of volunteers who develop free, portable and high-quality software solutions for digital typography. They specifically target embedded systems and focus on bringing small, efficient and ubiquitous products. This package contains all supplementary files (static library, headers and documentation) you need to develop your own programs using the FreeType 2 library.
#libfreetype6                : FreeType 2 font engine, shared library files
#
## regex (perl)
#libpcre3-dev                : Perl 5 Compatible Regular Expression Library - development files. This is a library of functions to support regular expressions whose syntax and semantics are as close as possible to those of the Perl 5 language.
##################################################
apt-get install mcrypt tidy libtidy-dev libxml2-dev libbz2-dev libmcrypt-dev libmhash-dev libmhash2 libcurl4-openssl-dev libpq-dev libpq5 libxml2 libxslt-dev libcurl3-dev libjpeg62-dev libpng3-dev libfreetype6-dev libfreetype6 libmagick9-dev libmcrypt4 libmhash-dev libpcre3-dev -y



# So we can use phpize to prepare PHP extensions for compiling
##################################################
apt-get install php-devel -y



# Install software for load testing
##################################################
apt-get install apache2-utils -y



# Install other software
##################################################
apt-get install subversion libmysqlclient15-dev -y





# nano syntax highlighting for ini files
cd /${BASE_INSTALL}/sources
wget http://webapp.org.ua/wp-content/uploads/2011/07/nanorc.tar
tar -xvvf nanorc.tar
mv ./usr/share/nano/ini.nanorc /usr/share/nano/ini.nanorc

# enables nano syntax highlighting
for i in `echo /usr/share/nano/*.nanorc` ; do echo include \"$i\" >> ~/.nanorc ; done;

   








#############################################################################################################################################################################################################
# FIREWALL SETUP ############################################################################################################################################################################################
#############################################################################################################################################################################################################

# packages used by firewall
apt-get install gawk aggregate

# vars
FIREHOL_VERSION=1.273
FIREHOL_DOWNLOAD_PATH="http://downloads.sourceforge.net/project/firehol/firehol/R5%20v"${FIREHOL_VERSION}"/firehol-"${FIREHOL_VERSION}".tar.bz2?r=&ts=1325565888&use_mirror=internode"

# download/unpack
cd /${BASE_FOLDER}/sources
wget ${FIREHOL_DOWNLOAD_PATH} -O firehol.tar.bz2
tar jxf firehol.tar.bz2
mv firehol-${FIREHOL_VERSION} firehol
cd /${BASE_FOLDER}/sources/firehol

# firehol folder
mkdir /etc/firehol

# move old script (get-iana.sh gets private ips)
chmod -x get-iana.sh
mv get-iana.sh get-iana.sh-old.log

# get latest script
wget http://firehol.cvs.sourceforge.net/viewvc/firehol/firehol/get-iana.sh?revision=1.14 -O get-iana.sh
chmod +x get-iana.sh

# modify script to not ask questions
sed -i 's/read x/x=yes/g' /${BASE_FOLDER}/sources/firehol/get-iana.sh

# run the script, now private ip should be updated
touch /etc/firehol/RESERVED_IPS
chmod +x /${BASE_FOLDER}/sources/firehol/get-iana.sh
/${BASE_FOLDER}/sources/firehol/get-iana.sh

# move firehol to the binary folder
mv /${BASE_FOLDER}/sources/firehol/firehol.sh /sbin/firehol; 

################################################################################
# config
################################################################################
echo '#!/sbin/firehol

version 5 

RS_TRUSTED_IPS="'${TRUSTED_IP}'"

server_ssh_ports="tcp/'${SSHD_PORT}'"
client_ssh_ports="default"

server_serveradminsecret_ports="tcp/'${SERVER_ADMIN_SECRET_PORT}'"
client_serveradminsecret_ports="default"

server_webadmin_ports="tcp/'${WEBADMIN_PORT}'"
client_webadmin_ports="default"

interface eth0 server src not "${UNROUTABLE_IPS}"
    
    # drop all traffic by default
	policy drop
    
    # protect against common attacks
	protection strong
    
    ## outgoing >>>
        client "ntp dns http https smtp smtps" accept
    
    ## incoming <<<   
        # server ident reject with tcp-reset 
        # server any nolog drop
        
        # basic ping/pong stuff, keep for convenience, remove if security nut
        server "icmp ping" accept
        
        # most services
        server "http https ICMP serveradminsecret webadmin" accept
        
        # ssh access for trusted ip only
        server ssh accept src "$RS_TRUSTED_IPS"

' > /etc/firehol/firehol.conf

################################################################################
# global defaults for firehol
################################################################################
echo '#To enable firehol at startup set START_FIREHOL=YES
START_FIREHOL=YES

#If you want to have firehol wait for an iface to be up add it here
WAIT_FOR_IFACE="eth0"
' > /etc/default/firehol

################################################################################
# init script
################################################################################
echo '#! /bin/sh
### BEGIN INIT INFO
# Provides:          firehol
# Required-Start:    $network $syslog
# Required-Stop:     $network 
# Default-Start:     2 3 4 5 
# Default-Stop:      0 1 6 
# Description: Starts firehol firewall configuration 
# short-description: firehol firewall configuration
### END INIT INFO

#includes lsb functions 
. /lib/lsb/init-functions

PATH=/sbin:/bin
NAME=firehol
DESC=Firewall

test -x /sbin/firehol || exit 0

set -e

[ -r /etc/default/firehol ] && . /etc/default/firehol

START_FIREHOL="$( echo $START_FIREHOL | /usr/bin/tr a-z A-Z)"

COMMAND="$1" 
test -n "$1" && shift

case "$COMMAND" in
  start)
        
        if [ "$START_FIREHOL" = "NO"  ]; then
                log_warning_msg "$DESC disabled via /etc/default/firehol"
                exit 0
        else 
                log_daemon_msg "Starting $DESC" "$NAME"
                /sbin/firehol start "$@" >/dev/null || log_end_msg 1
                log_end_msg 0
        fi
        ;;
  stop)
        log_daemon_msg "Stopping $DESC" "$NAME"
        /sbin/firehol stop "$@" >/dev/null || log_end_msg 1
        log_end_msg 0
        ;;
  helpme|wizard) 
        log_daemon_msg  "Starting $NAME wizard" 1>&2 
        /sbin/firehol wizard
        ;;
  restart|force-reload)
        if [ "$START_FIREHOL" = "NO"  ]; then
                log_warning_msg "$DESC disabled via /etc/default/firehol"
                exit 0
        else 
                log_daemon_msg "Restarting $DESC configuration"
                /sbin/firehol restart "$@" >/dev/null || log_end_msg 1
                log_action_end_msg 0 
        fi
        ;;
  *)
        N=/etc/init.d/$NAME
        log_action_msg "Usage: $N {start|stop|restart|force-reload} [<args>]" >&2
        exit 1
        ;;
esac

exit 0
' > /etc/init.d/firehol

# make init script executable
chmod +x /etc/init.d/firehol

# make firehol run at startup
update-rc.d firehol defaults

# run the firewall right now
/etc/init.d/firehol start

# firewall laoded
echo 'Firewall Loaded:' `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log









#############################################################################################################################################################################################################
# CONFIGURE DATA DISK #######################################################################################################################################################################################
#############################################################################################################################################################################################################

# create a placeholder data folder, the new disk will take its place when mounted, post install
mkdir /${DATA_DRIVE_LABEL}

# create the tmp data folder
mkdir /${DATA_DRIVE_LABEL}-tmp

cd /${BASE_FOLDER}/tmp

# find the linode config profile id (assumes there is only one, which is the default for a fresh linode)
wget "https://api.linode.com/index.cfm?api_key=${THE_API_KEY}&api_action=linode.config.list&linodeID=${THE_LINODE_MACHINE_ID}" -O 'config-profile.log' -q
cat config-profile.log | grep -oG 'ConfigID":.*[0-9].*DiskList' > config-profile-tmp.log
cat config-profile-tmp.log| grep -oG '[0-9]*' > config-profile-id.log
THE_LINODE_CONFIG_PROFILE_ID=$(cat config-profile-id.log)

# create the new disk
wget "https://api.linode.com/index.cfm?api_key=${THE_API_KEY}&api_action=linode.disk.create&linodeID=${THE_LINODE_MACHINE_ID}&Label=${DATA_DRIVE_LABEL}&Type=ext3&Size=${DATA_DRIVE_SIZE}" -O 'new-disk.log' -q

# edit the log file to show the (new) disk id
cat new-disk.log | grep -oG 'DiskID":.*[0-9]' > new-disk-tmp.log
cat new-disk-tmp.log | grep -oG '[0-9]*' > new-disk-id.log

#list the existing disks
wget "https://api.linode.com/index.cfm?api_key=${THE_API_KEY}&api_action=linode.config.list&linodeID=${THE_LINODE_MACHINE_ID}&configID=${THE_LINODE_CONFIG_PROFILE_ID}" -O 'existing-disks.log' -q

# edit the log file to show the (existing) disk ids
cat existing-disks.log | grep -oG 'DiskList":".*","RunLevel' > existing-disks-tmp.log
cat existing-disks-tmp.log | grep -oG '[0-9]*' > existing-disks-id.log

#create a var with all (existing) disk ids for new config profile
new_disk_config=''
while read line; do 
    new_disk_config=$new_disk_config','$line
done < existing-disks-id.log

# remove the first instance of ", "
new_disk_config=${new_disk_config:1} 

# append the newest disk id to the var
new_disk_config=$new_disk_config','$(cat new-disk-id.log)

# update the profile with the new disk configuration
wget "https://api.linode.com/index.cfm?api_key=${THE_API_KEY}&api_action=linode.config.update&linodeID=${THE_LINODE_MACHINE_ID}&configID=${THE_LINODE_CONFIG_PROFILE_ID}&diskList="${new_disk_config} -O 'config-profile.log' -q

# update fstab with the new data disk (non-executable disk)
sed -i '/xvda/ c\\/dev\/xvda       \/          ext3     noatime,errors=remount-ro 0       1' /etc/fstab
echo '/dev/xvdc       /data       ext3     defaults,nosuid,noexec,nodev 1 2' >> /etc/fstab

# on reboot the new linode configurtion-profile will be loaded, we will reboot and run post-install script at the end of this script










#############################################################################################################################################################################################################
# WEB DEV - PREPARE #########################################################################################################################################################################################
#############################################################################################################################################################################################################

# set the versions for each download, if the download urls & names are kept consistant then you should only need to change the version number 
NGINX_VERSION=1.1.11
PHP_VERSION=5.3.8
LIBEVENT_VERSION=2.0.16
MEMCACHED_VERSION=1.4.10
PECL_APC_VERSION=3.1.9
PECL_MEMCACHE_VERSION=2.2.6
SUHOSIN_VERSION=0.9.32.1
PHP_MY_ADMIN_VERSION=3.4.8

# set the path to each download
NGINX_DOWNLOAD_PATH=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
PHP_DOWNLOAD_PATH=http://au2.php.net/get/php-${PHP_VERSION}.tar.gz/from/au.php.net/mirror
LIBEVENT_DOWNLOAD_PATH=https://github.com/downloads/libevent/libevent/libevent-${LIBEVENT_VERSION}-stable.tar.gz
MEMCACHED_DOWNLOAD_PATH=http://memcached.googlecode.com/files/memcached-${MEMCACHED_VERSION}.tar.gz
PECL_APC_DOWNLOAD_PATH=http://pecl.php.net/get/APC-${PECL_APC_VERSION}.tgz
PECL_MEMCACHE_DOWNLOAD_PATH=http://pecl.php.net/get/memcache-${PECL_MEMCACHE_VERSION}.tgz
SUHOSIN_DOWNLOAD_PATH=http://download.suhosin.org/suhosin-${SUHOSIN_VERSION}.tar.gz
PHP_MY_ADMIN_DOWNLOAD_PATH=http://sourceforge.net/projects/phpmyadmin/files%2FphpMyAdmin%2F${PHP_MY_ADMIN_VERSION}%2FphpMyAdmin-${PHP_MY_ADMIN_VERSION}-english.tar.gz/download

# go to source folder, then download the sources we'll need
cd /${BASE_FOLDER}/sources

### LATEST VERSIONS - 6 December 2011 ###
wget ${NGINX_DOWNLOAD_PATH} -O nginx.tar.gz
wget ${PHP_DOWNLOAD_PATH} -O php.tar.gz
wget ${LIBEVENT_DOWNLOAD_PATH} -O libevent.tar.gz
wget ${MEMCACHED_DOWNLOAD_PATH} -O memcached.tar.gz
wget ${PECL_APC_DOWNLOAD_PATH} -O apc.tar.gz
wget ${PECL_MEMCACHE_DOWNLOAD_PATH} -O memcache.tar.gz
wget ${SUHOSIN_DOWNLOAD_PATH} -O suhosin.tar.gz
wget ${PHP_MY_ADMIN_DOWNLOAD_PATH} -O phpmyadmin.tar.gz

# unpack all the sources
tar zxf nginx.tar.gz
tar zxf php.tar.gz
tar zxf libevent.tar.gz
tar zxf memcached.tar.gz
tar zxf apc.tar.gz
tar zxf memcache.tar.gz
tar zxf suhosin.tar.gz
tar zxf phpmyadmin.tar.gz

# rename folders to a consistant format
mv nginx-${NGINX_VERSION} nginx
mv php-${PHP_VERSION} php
mv libevent-${LIBEVENT_VERSION}-stable libevent
mv memcached-${MEMCACHED_VERSION} memcached
mv APC-${PECL_APC_VERSION} apc
mv memcache-${PECL_MEMCACHE_VERSION} memcache
mv suhosin-${SUHOSIN_VERSION} suhosin
mv phpMyAdmin-${PHP_MY_ADMIN_VERSION}-english phpmyadmin

# don't show servername or version in responses
sed -i 's/<center>\" NGINX_VER \"<\/center>/<center>server<\/center>/g' /${BASE_FOLDER}/sources/nginx/src/http/ngx_http_special_response.c
sed -i 's/<center>nginx<\/center>/<center>server<\/center>/g' /${BASE_FOLDER}/sources/nginx/src/http/ngx_http_special_response.c










#############################################################################################################################################################################################################
# WEB DEV - INSTALL #########################################################################################################################################################################################
#############################################################################################################################################################################################################

# time log
echo Building Nginx: `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# build nginx
cd /${BASE_FOLDER}/sources/nginx
./configure --with-http_gzip_static_module --with-http_ssl_module --conf-path=/${BASE_FOLDER}/confs/nginx/nginx.conf --http-log-path=/${BASE_FOLDER}/logs/nginx-access.log --error-log-path=/${BASE_FOLDER}/logs/nginx-error.log --user=www-data --group=www-data --sbin-path=/usr/local/sbin --pid-path=/${BASE_FOLDER}/logs/nginx.pid --lock-path=/${BASE_FOLDER}/logs/nginx.lock
make && make install

# time log
echo Building Libevent: `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# build libevent
cd /${BASE_FOLDER}/sources/libevent
./configure
make && make install

# time log
echo Building PHP: `date` >> /${BASE_FOLDER}/msgs/install.log

# build php
cd /${BASE_FOLDER}/sources/php
./configure --enable-fpm  --enable-cli --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql-sock --with-pdo-mysql=mysqlnd --with-zlib --with-bz2 --enable-zip --with-openssl --with-mcrypt --with-mhash --with-curl --with-gd --with-jpeg-dir --with-png-dir --enable-ftp --enable-exif --with-freetype-dir --enable-calendar --enable-soap --enable-mbstring --with-xsl --with-xmlrpc --enable-bcmath --with-gettext --enable-dba --enable-shmop --enable-sockets --enable-sysvmsg --enable-wddx  --with-tidy --with-pcre-dir  --enable-gd-native-ttf --with-kerberos --with-pear
make all install

# time log
echo Building PHP Finished: `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# copy the default php config from source & create an alias
cp /${BASE_FOLDER}/sources/php/php.ini-production /${BASE_FOLDER}/confs/php.ini
ln -s /${BASE_FOLDER}/confs/php.ini /usr/local/lib/php.ini

# build memcached
cd /${BASE_FOLDER}/sources/memcached
./configure
make && make install

# build memcache <--- PHP extension
cd /${BASE_FOLDER}/sources/memcache
phpize
./configure --with-php-config=/usr/local/bin/php-config --enable-memcache
make && make install

# build apc <--- PHP extension
cd /${BASE_FOLDER}/sources/apc
phpize
./configure --with-php-config=/usr/local/bin/php-config --enable-apc
make && make install

# build suhosin <--- PHP extension
cd /${BASE_FOLDER}/sources/suhosin
phpize
./configure
make && make install

# mysql functions
function mysql_install {
	# $1 - the mysql root password

	#if [ ! -n "$1" ]; then
	#	echo "mysql_install() requires the root pass as its first argument"
	#	return 1;
	#fi

	echo "mysql-server-5.1 mysql-server/root_password password ${MYSQL_ROOT_PW}" | debconf-set-selections
	echo "mysql-server-5.1 mysql-server/root_password_again password ${MYSQL_ROOT_PW}" | debconf-set-selections
	apt-get -y install mysql-server mysql-client

	echo "Sleeping while MySQL starts up for the first time..."
	sleep 5
	
	# create an alias for the config file
	ln -s /etc/mysql/my.cnf /${BASE_FOLDER}/confs/my.cnf

        # create my.cnf for root (only) so root dosnt have to login to mysql        
        touch ~/.my.cnf
        chmod 0600 ~/.my.cnf
        
        echo "[client]
        user = root
        password = $MYSQL_ROOT_PW
        " > ~/.my.cnf;
	
}

function mysql_tune {
	# Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%

	# $1 - the percent of system memory to allocate towards MySQL

	if [ ! -n "$1" ];
		then PERCENT=40
		else PERCENT="$1"
	fi

	MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
	MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
	MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

	# mysql config options we want to set to the percentages in the second list, respectively
	OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
	DISTLIST=(75 1 1 1 5 15)

	for opt in ${OPTLIST[@]}; do
		sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
	done

	for i in ${!OPTLIST[*]}; do
		val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
		if [ $val -lt 4 ]
			then val=4
		fi
		config="${config}\n${OPTLIST[$i]} = ${val}M"
	done

	sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

	touch /tmp/restart-mysql
}

# install and tune mysql
mysql_install
mysql_tune










#############################################################################################################################################################################################################
# WEB DEV - CONFIGURE - NGINX ###############################################################################################################################################################################
#############################################################################################################################################################################################################

# create sym link for nginx binary
ln -s /usr/local/sbin/nginx /usr/bin/nginx

# base-nginx config
echo "
# reference: https://calomel.org/nginx.html

pid 		        /${BASE_FOLDER}/logs/nginx.pid;
user		        www-data www-data;
worker_processes 	3;

events {
   worker_connections  1024;
}

http {

    ## Timeouts     
    client_body_timeout     60;
    client_header_timeout   60;
    keepalive_timeout       300 300;
    send_timeout            60;

    ## General Options
    charset                 utf-8;
    default_type            application/octet-stream;
    ignore_invalid_headers  on;
    include                 /rs/confs/nginx/mime.types;
    keepalive_requests      20;
    max_ranges              0;
    recursive_error_pages   on;
    sendfile                on;
	server_tokens           off;
    source_charset          utf-8;

    ## Request limits
    limit_req_zone  \$binary_remote_addr  zone=gulag:1m   rate=60r/m;

    ## Compression
    gzip              on;
    gzip_buffers      16 8k;
    gzip_comp_level   4;
    gzip_http_version 1.0;
    gzip_min_length   1280;
    gzip_types        text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript image/x-icon image/bmp;
    gzip_vary         on;

    ## Log Format
    log_format  combinedplus    '\$remote_addr \$host \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\" \$ssl_cipher \$request_time';
    
    ## Logs
    access_log  /var/log/nginx-default-access.log combinedplus;
    error_log   /var/log/nginx-default-error.log warn;

    index index.html index.htm index.php;
    
    server {
      listen $PRIMARY_IP_ADDRESS:80 default_server;
      server_name _;
      rewrite ^       http://www.radicalsystems.net permanent;
    }

    # include the file that has all the nginx config locations	
	include /${BASE_FOLDER}/confs/nginx-sites.conf;

}" > /${BASE_FOLDER}/confs/nginx/nginx.conf

# create alias for default nginx binary path
mkdir /usr/local/nginx/sbin/
ln -s /usr/local/sbin/nginx /usr/local/nginx/sbin/nginx

# nginx init script (or http://www.debianadmin.com/images/nginx)
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/sbin/nginx #DAEMON=/usr/local/nginx/sbin/nginx
NAME=nginx
DESC=nginx

test -x $DAEMON || exit 0

# Include nginx defaults if available
if [ -f /etc/default/nginx ] ; then
        . /etc/default/nginx
fi

set -e

case "$1" in
  start)
        echo -n "Starting $DESC: "
        start-stop-daemon --start --quiet --pidfile /'${BASE_FOLDER}'/logs/nginx.pid --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --quiet --pidfile /'${BASE_FOLDER}'/logs/nginx.pid --exec $DAEMON
        echo "$NAME."
        ;;
  restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --quiet --pidfile /'${BASE_FOLDER}'/logs/nginx.pid --exec $DAEMON
        sleep 1
        start-stop-daemon --start --quiet --pidfile /'${BASE_FOLDER}'/logs/nginx.pid --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  reload)
      echo -n "Reloading $DESC configuration: "
      start-stop-daemon --stop --signal HUP --quiet --pidfile /'${BASE_FOLDER}'/logs/nginx.pid --exec $DAEMON
      echo "$NAME."
      ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/nginx

# make nginx init script executable
chmod +x /etc/init.d/nginx

# make nginx start at boot time
/usr/sbin/update-rc.d nginx defaults





#############################################################################################################################################################################################################
# WEB DEV - CONFIGURE - PHP #################################################################################################################################################################################
#############################################################################################################################################################################################################

# copy the default php config from source & create an alias
cp /${BASE_FOLDER}/sources/php/php.ini-production /${BASE_FOLDER}/confs/php.ini
ln -s /${BASE_FOLDER}/confs/php.ini /usr/local/lib/php.ini

# edit the php config with some generic settings for - apc & the other extentions we need
echo '
extension=memcache.so
extension=apc.so
extension=suhosin.so

[APC]
apc.shm_segments = 1
apc.optimization = 0
apc.shm_size = 128M
apc.ttl = 0
apc.user_ttl = 3600
apc.gc_ttl = 600
apc.num_files_hint = 1024
apc.mmap_file_mask = /tmp/apc.XXXXXX
apc.slam_defense = off

' >> /${BASE_FOLDER}/confs/php.ini

# copy the default php-fpm config from source & create an alias
cp /${BASE_FOLDER}/sources/php/sapi/fpm/php-fpm.conf /${BASE_FOLDER}/confs/php-fpm.conf
ln -s /${BASE_FOLDER}/confs/php-fpm.conf /usr/local/etc/php-fpm.conf

# php-fpm config changes
# sed -i 's/xxx/yyy/g' /${BASE_FOLDER}/confs/php-fpm.conf
# make sure you escape all instances of "/" in a string with "\", so it will look like this "\/"

# pid = run/php-fpm.pid
# error_log = /rs/logs/php-fpm.log
# emergency_restart_threshold = 8
# listen.owner = www-data
# listen.group = www-data
# listen.mode = 0666
# user = www-data
# group = www-data
# pm = static
# pm.max_children = 10

sed -i 's/;pid = run\/php-fpm.pid/pid = run\/php-fpm.pid/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i "s/;error_log = log\/php-fpm.log/error_log = \/${BASE_FOLDER}\/logs\/php-fpm.log/g" /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 8/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/;listen.owner = nobody/listen.owner = www-data/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/;listen.group = nobody/listen.group = www-data/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/;listen.mode = 0666/listen.mode = 0666/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/user = nobody/user = www-data/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/group = nobody/group = www-data/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/pm = dynamic/pm = static/g' /${BASE_FOLDER}/confs/php-fpm.conf
sed -i 's/pm.max_children = 50/pm.max_children = 10/g' /${BASE_FOLDER}/confs/php-fpm.conf

# php-fpm init script
cp /${BASE_FOLDER}/sources/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
/usr/sbin/update-rc.d php-fpm defaults










#############################################################################################################################################################################################################
# WEB DEV - CONFIGURE - SSL #################################################################################################################################################################################
#############################################################################################################################################################################################################

cd /${BASE_FOLDER}/ssl

# create file containing password for ssl (for roots eyes only)    
touch ~/.sslpass
chmod 0600 ~/.sslpass
echo ${SSL_PASSWORD} > ~/.sslpass;

# private key
openssl genrsa -des3 -out ssl.key -passout file:/root/.sslpass 2048

# vars for csr
SSL_VARS="/CN=${SSL_COMMON_NAME}/O=${SSL_ORG}/OU=${SSL_ORG_UNIT}/L=${SSL_CITY}ST=${SSL_STATE}/C=${SSL_COUNTRY}"

# csr (Certificate Signing Request)
openssl req -new -key ssl.key -out ssl.csr -subj "${SSL_VARS}" -passin file:/root/.sslpass

# remove password (so web server doesnt ask for it on a restart)
cp ssl.key ssl.key.org
openssl rsa -in ssl.key.org -out ssl.key -passin file:/root/.sslpass

# create the ssl certificate
openssl x509 -req -days 365 -in ssl.csr -signkey ssl.key -out ssl.crt

# secure the key
chown root:www-data /${BASE_FOLDER}/ssl/ssl.key /${BASE_FOLDER}/ssl/ssl.key.org
chmod 640 /${BASE_FOLDER}/ssl/ssl.key /${BASE_FOLDER}/ssl/ssl.key.org

# create htpass style passwords
cd /${BASE_FOLDER}/passwords/
htpasswd -b -c .htpasswd ${AUTH_TEST_USER} ${AUTH_TEST_PASS}
chown root:www-data .htpasswd 
chmod 640 .htpasswd 










#############################################################################################################################################################################################################
# FINAL BITS ################################################################################################################################################################################################
#############################################################################################################################################################################################################

# create a dev folder for some scripts
mkdir /${DATA_DRIVE_LABEL}-tmp/dev

# create phpinfo page
echo '<?php
phpinfo();
?>' > /${DATA_DRIVE_LABEL}-tmp/dev/phpinfo.php

# move phpmyadmin somewhere useful
mv /${BASE_FOLDER}/sources/phpmyadmin/ /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin

# config for phpmyadmin (set to 127.0.0.1 to avoid dns issues)
cp /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin/config.sample.inc.php /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin/config.inc.php
chown root:www-data /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin/config.inc.php
chmod 440 /${DATA_DRIVE_LABEL}-tmp/dev/phpmyadmin/config.inc.php

# copy the apc reporting file somewhere useful
cp /${BASE_FOLDER}/sources/apc/apc.php /${DATA_DRIVE_LABEL}-tmp/dev/apc.php

# give easy access to common files
chown $USER_NAME:root /rs/confs/nginx/nginx.conf
chown $USER_NAME:root /rs/confs/nginx-sites.conf
chown $USER_NAME:root /rs/confs/nginx/mime.types
chown $USER_NAME:root /rs/confs/nginx/fastcgi_params
chown $USER_NAME:root /etc/mysql/my.cnf 
chown $USER_NAME:root /rs/confs/php-fpm.conf
chown $USER_NAME:root /rs/confs/php.ini 
chown $USER_NAME:root /etc/firehol/firehol.conf

ln -s /rs/confs/nginx/nginx.conf     /home/$USER_NAME/nginx.conf
ln -s /rs/confs/nginx-sites.conf     /home/$USER_NAME/nginx-sites.conf
ln -s /rs/confs/nginx/mime.types     /home/$USER_NAME/mime.types
ln -s /rs/confs/nginx/fastcgi_params /home/$USER_NAME/fastcgi_params
ln -s /etc/mysql/my.cnf              /home/$USER_NAME/my.cnf
ln -s /rs/confs/php-fpm.conf         /home/$USER_NAME/php-fpm.conf
ln -s /rs/confs/php.ini              /home/$USER_NAME/php.ini
ln -s /etc/firehol/firehol.conf      /home/$USER_NAME/firehol.conf



echo "#!/bin/bash

# clear out any OSX files
find /rs/scripts -name '*.DS_Store' -exec rm {} \;

# everything owned by root
chown $USER_NAME:root -R /rs/scripts

# standard permissions
find /rs/scripts -type d -exec chmod 755 {} \;
find /rs/scripts -type f -exec chmod 644 {} \;

# make scripts executable
find /rs/scripts -name '*.sh' -exec chmod +x {} \;

" > /${BASE_FOLDER}/scripts/cleanup.sh

chmod +x /${BASE_FOLDER}/scripts/cleanup.sh





# create a log file with ALL the versions/downloads of software that we compiled manually
# in the future, all this will be done through custom debian packages
echo "
NGINX_VERSION=${NGINX_VERSION}
PHP_VERSION=${PHP_VERSION}
LIBEVENT_VERSION=${LIBEVENT_VERSION}
MEMCACHED_VERSION=${MEMCACHED_VERSION}
PECL_APC_VERSION=${PECL_APC_VERSION}
PECL_MEMCACHE_VERSION=${PECL_MEMCACHE_VERSION}
SUHOSIN_VERSION=${SUHOSIN_VERSION}
PHP_MY_ADMIN_VERSION=${PHP_MY_ADMIN_VERSION}
FIREHOL_VERSION=${FIREHOL_VERSION}

NGINX_DOWNLOAD_PATH=${NGINX_DOWNLOAD_PATH}
PHP_DOWNLOAD_PATH=${PHP_DOWNLOAD_PATH}
LIBEVENT_DOWNLOAD_PATH=${LIBEVENT_DOWNLOAD_PATH}
MEMCACHED_DOWNLOAD_PATH=${MEMCACHED_DOWNLOAD_PATH}
PECL_APC_DOWNLOAD_PATH=${PECL_APC_DOWNLOAD_PATH}
PECL_MEMCACHE_DOWNLOAD_PATH=${PECL_MEMCACHE_DOWNLOAD_PATH}
SUHOSIN_DOWNLOAD_PATH=${SUHOSIN_DOWNLOAD_PATH}
PHP_MY_ADMIN_DOWNLOAD_PATH=${PHP_MY_ADMIN_DOWNLOAD_PATH}
FIREHOL_DOWNLOAD_PATH=${FIREHOL_DOWNLOAD_PATH}
" > /${BASE_FOLDER}/msgs/sources.log





# make a copy of the default /etc/rc.local script
cp /etc/rc.local /etc/rc.local-tmp

# create the post-server-install script
echo '#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

echo Moving the temp data Folder: `date` >> /'${BASE_FOLDER}'/msgs/install.log
echo "" >> /'${BASE_FOLDER}'/msgs/install.log

# move files from tmp to real data folder
mv /'${DATA_DRIVE_LABEL}'-tmp/* /'${DATA_DRIVE_LABEL}'/
rm -rf /'${DATA_DRIVE_LABEL}'-tmp

echo Post Install Script Complete: `date` >> /'${BASE_FOLDER}'/msgs/install.log 

# reset the rc.local script
mv /etc/rc.local-tmp /etc/rc.local

exit 0

' > /etc/rc.local





# what packages are now installed
dpkg --get-selections > /${BASE_FOLDER}/msgs/software-complete.log

# clean up sources folder
rm -rf /${BASE_FOLDER}/sources/*

# note the finish time
echo Script Complete. Restarting... `date` >> /${BASE_FOLDER}/msgs/install.log
echo "" >> /${BASE_FOLDER}/msgs/install.log

# leave a token so we know the script has already been run
touch /stack-script-complete

# restart the machine (this will cause /etc/rc.local to run a post-install script, one-time only, then we are done!
init 6





# make sure this never runs more then once (this stackscript restarts to properly mount the new disk and this if is required to make sure it doesn't loop)
fi