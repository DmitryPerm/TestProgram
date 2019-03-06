#!/bin/sh

# Parameters connect ----------------------------------------------
FTPHOST="ftp-edi.kontur.ru"
FTPSERVERONLY="ftp-edi.kontur.ru"
FTPUSER="login"
FTPPASS="password"
#
# Path
REMOTEIN="Inbox"
REMOTEOUT="Outbox"
FILES_FROM_SERVER="/usr/ns2000/edi/filesFromServer.txt"
LOCALIN="/usr/ns2000/edi/Inbox"
LOCALOUT="/usr/ns2000/edi/Outbox"
LOCALCOPY="/usr/ns2000/edi/Copy.out"
LOCALPREPARE="/usr/ns2000/edi/ReadyToSend/"
ERROR_FILE="/usr/ns2000/ftp.failed"
LOGS_FILE="/usr/ns2000/edi.logs"
# Email
EMAIL="rda@7r.perm.ru" # e-mail
# 
THEME="EDI Kontur error (Logistika)"
PINGMSG="Problem ping FTPHOST"
GETMSG="Problem get info FTPHOST"
PUTMSG="Problem send info FTPHOST"
ERROR_IS_FOUND="Total: fail, errors is detected."
ERROR_IS_NOT_FOUND="Total: success, errors is not detected."
# One script every SECONDS_PER_SCRIPT sec
SECONDS_PER_SCRIPT=10
POSITION_IN_QUEUE=1
WAITING_FOR_TURN=$(($SECONDS_PER_SCRIPT*$POSITION_IN_QUEUE))
# Init variables
ERRORS_COUNT=0
# Parameters ----------------------------------------------

# Function ------------------------------------------------
# Write logs
infoToLogs() {
    echo -e "$1" >> $LOGS_FILE
}

# Write info for last error
# Parameter = error
infoToErrors() {
    echo -e "$1" > $ERROR_FILE
}

# Servers ping
pingServer() {
    ping "$1" -c 2
}

# Send email
# Parameter = message text
sendEmail() {
mail -s "$THEME" $EMAIL <<EOF
"$1"
EOF
}

# Find problems ping
# Parameter = message text
findPingProblems() {
if [[ "$?" != 0 ]]; then
    sendEmail "$1"
    infoToLogs "$1"
    ERRORS_COUNT=1
    infoToLogs "End ping."
    exit
else
    infoToLogs "Success."
fi
}

# Find ftp problems
# Parameter = message text
findFtpProblems() {
ERRORS_SIZE=$(du -b $ERROR_FILE | cut -f 1)
if [[ $ERRORS_SIZE != 0 ]]; then
    if grep -Fq "No such file or directory" $ERROR_FILE
    then
       echo "ignore, no errors"
    else
       ERRORS_COUNT=1
       sendEmail "$1"
    fi
fi
}

# Getting files from server
# Example: "file1.txt file2.txt"
getFilesListFromServer() {
cd $LOCALIN
GET_RESULT="$(ftp -n $FTPHOST 2> $ERROR_FILE <<EOF
quote USER $FTPUSER
quote PASS $FTPPASS
binary
cd $REMOTEIN
prompt
ls . $FILES_FROM_SERVER
a
pwd
EOF
)"
# Getting files name from $FILES_FROM_SERVER
filesList=""
counter=0
while read line; do
  counter=$[$counter+1]
  if [[ "$counter" -gt 50 ]]
  then
    break
  fi
  fileName=${line##* }
  filesList+=" "$fileName
done <$FILES_FROM_SERVER
echo $filesList
}

# Getting files with writing to logs
getFilesFromServer() {
filesList="$1"
cd $LOCALIN
GET_RESULT="$(ftp -n $FTPHOST 2> $ERROR_FILE <<EOF
quote USER $FTPUSER
quote PASS $FTPPASS
binary
cd $REMOTEIN
prompt
ls
mget $filesList
a
pwd
mdelete $filesList
a
EOF
)"
if [[ $GET_RESULT == *Not\ connected* ]]; then
    infoToErrors "Not connected"
fi
infoToLogs "$GET_RESULT"
}

# Sending files with writing to logs
sendFilesToServer() {
cd $LOCALPREPARE
SEND_FILES="$(ls -l|awk p++)"
if [[ $SEND_FILES != "" ]]; then
    infoToLogs "$SEND_FILES"
fi
SEND_RESULT="$(ftp -n $FTPHOST 2> $ERROR_FILE <<EOF
quote USER $FTPUSER
quote PASS $FTPPASS
binary
cd $REMOTEOUT
prompt
mput *
a
pwd
EOF
)"
if [[ $SEND_RESULT == *Not\ connected* ]]; then
    infoToErrors "Not connected"
fi
infoToLogs "$SEND_RESULT"
}

# Moving files to backup directory
backupOutFiles() {
if [[ "$(ls -A $LOCALPREPARE)" ]]; then
    infoToLogs "Files to backup."
    mv -f $LOCALPREPARE/*.* $LOCALCOPY
fi
}

# Moving files to directory 
filesToPrepareCatalog() {
if [[ "$(ls -A $LOCALOUT)" ]]; then
    infoToLogs "Move files to preparation catalog."
    mv -f $LOCALOUT/*.* $LOCALPREPARE
fi
}

# 1 - GLN (login)
# 2 - pass
transferEdi() {
FTPUSER="$1"
FTPPASS="$2"

DATE_TIME=$(date '+%F %T') # Time start script
infoToLogs "\n\n-----------------------------------------------------\nNew logs record ($DATE_TIME)"

# infoToLogs "Start ping.---------------------------"
# ping $FTPSERVERONLY -c 2
# findPingProblems "$PINGMSG"
# infoToLogs "End ping."

infoToLogs "Start getting files.------------------"
filesListFromServer=$(getFilesListFromServer)
getFilesFromServer "$filesListFromServer"
findFtpProblems "$GETMSG"
infoToLogs "End getting files."

infoToLogs "Start sending files.------------------"
filesToPrepareCatalog
sendFilesToServer
findFtpProblems "$PUTMSG"
infoToLogs "End sending files."

if [[ $ERRORS_COUNT == 0 ]]; then
    backupOutFiles
    infoToLogs "$ERROR_IS_NOT_FOUND"
else
    infoToLogs "$ERROR_IS_FOUND"
fi
}
# main function

sleep "$WAITING_FOR_TURN"

transferEdi "login1" "pass1"

transferEdi "login2" "pass2"

exit 0
# End script
