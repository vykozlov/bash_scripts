#!/bin/bash
########################################################
#   Script to backup a remote directory (e.g. website) #
#   Executed typically every day by cronjob in Linux   #
#   Backup is incremental:                             #
#   History is kept of every weekday for one week,     #
#   and for 1st and 15th day of a month.               #
#                                                      #
#   Important is -al option of cp!                     #
#   i.e. we use 'hardlinks' to save space              #
#                                                      #
#   'Simple' version, meaning directories              #
#   backup.now                                         #
#   backup.1                                           #
#   backup.15                                          #
#   backup.wday1..7                                    #
#   have to be manually created beforehand             #
#                                                      #
#  !vkozlov 2014..2015                                 #
########################################################

######## CONFIG for the script ########
# user on the remote site
user="user"
# ssh_key to use to connect to remoteSite
ssh_key="full/path/ssh.key"
# remote Site where the directory to be backed up is
remoteSite="your.webaddress.here" #example.org
# the directory to be backed up ("/" at the end is important!)
remotePath="/home/www/website/"
# where to store localy
localBackupPath=$HOME/backup_site
# to whom the report is sent
mailTo=your_admin_email@example.org
# for directories, please, keep "/" at the end!
# number of elements is 3, if you want to add more, then also modify "rsync" string below!
# remotePathExclude=('dir1/' 'dir2/' 'dir3/')
# local log/history file of backups
remoteBackupLog="remoteBackupLog.txt"

# hour when to send notification email
emailHour=5

# flag to tag if there was an error
ISERROR=0
######## END of CONFIG ########

# print the date that the script was run on
echo -e "\n==> Copy script run at $(date)\c" >> $localBackupPath/$remoteBackupLog
echo -e "\n" >> $localBackupPath/$remoteBackupLog

#rm -rf $localBackupPath/backup.5
#mv $localBackupPath/backup.3 $localBackupPath/backup.5
#mv $localBackupPath/backup.1 $localBackupPath/backup.3

###  Copy DATA from the main website site  ### 
#bckLogMess=`rsync -avzPe ssh --delete --exclude ${websiteEXCLUDE[0]} --exclude ${websiteEXCLUDE[1]} --exclude ${websiteEXCLUDE[2]} user@$remoteSite:$remotePath $localBackupPath/backup.now/`
bckLogMess=`rsync -avzPe "ssh -i ${ssh_key}" --delete $user@$remoteSite:$remotePath $localBackupPath/backup.now/`
rm -rf $localBackupPath/backup.wday$(date +%u)
cp -al $localBackupPath/backup.now $localBackupPath/backup.wday$(date +%u) # creates 'hard links' according to the week day; could also be usefull to check '--link-dest' option of rsync
if [ $(date +%d) -eq 1 ]; then
   rm -rf $localBackupPath/backup.1
   cp -al $localBackupPath/backup.now $localBackupPath/backup.1 # creates 'hard links' for first day of month; could also be usefull to check '--link-dest' option of rsync
fi
if [ $(date +%d) -eq 15 ]; then
   rm -rf $localBackupPath/backup.15
   cp -al $localBackupPath/backup.now $localBackupPath/backup.15 # creates 'hard links' for 15th day of month; could also be usefull to check '--link-dest' option of rsync
fi

if [ $? -eq 0 ]
 then 
    logMessage="---> $remotePath @ $remoteSite successfully backed up from the main Website PC ($remoteSite)"
 else 
    logMessage="!!!! $remotePath directory @ $remoteSite UNSUCCESSFULLY copied from the main Website PC ($remoteSite) !!!"
    ISERROR=1
fi 

   echo "$logMessage" >> $localBackupPath/$remoteBackupLog
   echo "$bckLogMess" >> $localBackupPath/$remoteBackupLog   

### Sending a message with the report in case of 'emailHour' or error event
hourNow=$(date +"%H")
if [ $ISERROR -eq 1 -o $hourNow -eq $emailHour ]; then
   echo "Hallo ;-)

   On $(date):
   $logMessage
   ISERROR=$ISERROR
   
   More in $localBackupPath/$remoteBackupLog.
   Your script, $BASH_SOURCE" | mail -s $remoteBackupLog $mailTo
fi
