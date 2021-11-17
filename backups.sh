#!/bin/bash

# Enable logging
set -xo pipefail
exec 1> >(tee -a "/var/log/backupscript.log") 2>&1

# Variables:
DATETIME=`date +%b_%d_%Y-%H_%M_%S`
DIRECTORY=/var/www/wordpress
S3_BUCKET=thisisthebucketname/wordpress/
APP_NAME=wordpress
PATH_TO_LOGGING=/var/log/backupscript.log
EMAIL=user@email.tld
DB_DUMP=$APP_NAME-DB-$DATETIME.sql
TAR_FILE=$APP_NAME-$DATETIME.tar.gz

function database_dump {
    mysqldump --single-transaction --add-drop-database --all-databases > /tmp/backup/$DB_DUMP

    status=$(echo $?)
    handle_errors ${status}
}

function backup_dir_tar {
    tar -czvf /tmp/backup/$TAR_FILE $DIRECTORY; then
    
    status=$(echo $?)
    handle_errors ${status}
}

function send_tar_to_obj {
    s3cmd put /tmp/backup/$TAR_FILE s3://$S3_BUCKET -e 
    
    status=$(echo $?)
    handle_errors ${status}

}
function send_db_dump_to_obj {
    s3cmd put /tmp/backup/$DB_DUMP s3://$S3_BUCKET -e
    status=$(echo $?)
    handle_errors ${status}

}
function handle_errors () {
  if [ "$1" != "0" ]; then
    echo "$APP_NAME Backup Failed! Please check $PATH_TO_LOGGING for more details" | mail -s "$APP_NAME Backup Failed!" $EMAIL
    exit 1
  fi
}
function cleanup {
    rm /tmp/backup/$DB_DUMP
    rm /tmp/backup/$TAR_FILE
}
function main {
    database_dump
    backup_dir_tar
    send_tar_to_obj
    send_db_dump_to_obj
    cleanup
}

main
