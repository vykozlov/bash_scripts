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
# remote PC where the directory to be backed up is
websitePC="your.webaddress.here" #example.org
# the directory to be backed up ("/" at the end is important!)
websiteREMOTE="/home/www/website/"
# where to store localy
websiteBACKUP=$HOME/backup_website
# to whom the report is sent
mailTo=your_admin_email@example.org
# for directories, please, keep "/" at the end!
# number of elements is 3, if you want to add more, then also modify "rsync" string below!
#websiteEXCLUDE=('dir1/' 'dir2/' 'dir3/')
# local log/history file of backups
websiteCopyLOG=".backup_dir-log.txt"

# hour when to send notification email
emailHour=5

# flag to tag if there was an error
ISERROR=0
######## END of CONFIG ########

# print the date that the script was run on
echo -e "\n==> Copy script run at $(date)\c" >> $websiteBACKUP/$websiteCopyLOG
echo -e "\n" >> $websiteBACKUP/$websiteCopyLOG

#rm -rf $websiteBACKUP/backup.5
#mv $websiteBACKUP/backup.3 $websiteBACKUP/backup.5
#mv $websiteBACKUP/backup.1 $websiteBACKUP/backup.3

###  Copy DATA from the main website site  ### 
#bckLogMess=`rsync -avzPe ssh --delete --exclude ${websiteEXCLUDE[0]} --exclude ${websiteEXCLUDE[1]} --exclude ${websiteEXCLUDE[2]} user@$websitePC:$websiteREMOTE $websiteBACKUP/backup.now/`
bckLogMess=`rsync -avzPe ssh --delete user@$websitePC:$websiteREMOTE $websiteBACKUP/backup.now/`
rm -rf $websiteBACKUP/backup.wday$(date +%u)
cp -al $websiteBACKUP/backup.now $websiteBACKUP/backup.wday$(date +%u) # creates 'hard links' according to the week day; could also be usefull to check '--link-dest' option of rsync
if [ $(date +%d) -eq 1 ]; then
   rm -rf $websiteBACKUP/backup.1
   cp -al $websiteBACKUP/backup.now $websiteBACKUP/backup.1 # creates 'hard links' for first day of month; could also be usefull to check '--link-dest' option of rsync
fi
if [ $(date +%d) -eq 15 ]; then
   rm -rf $websiteBACKUP/backup.15
   cp -al $websiteBACKUP/backup.now $websiteBACKUP/backup.15 # creates 'hard links' for 15th day of month; could also be usefull to check '--link-dest' option of rsync
fi

if [ $? -eq 0 ]
 then 
    edwDIRMESS="---> $websiteREMOTE @ $websitePC successfully backed up from the main Website PC ($websitePC)"
 else 
    edwDIRMESS="!!!! $websiteREMOTE directory @ $websitePC UNSUCCESSFULLY copied from the main Website PC ($websitePC) !!!"
    ISERROR=1
fi 

   echo "$edwDIRMESS" >> $websiteBACKUP/$websiteCopyLOG
   echo "$bckLogMess" >> $websiteBACKUP/$websiteCopyLOG   

### Sending a message with the report in case of 'emailHour' or error event
hourNow=$(date +"%H")
if [ $ISERROR -eq 1 -o $hourNow -eq $emailHour ]; then
   echo "Hallo ;-)

   On $(date):
   $edwDIRMESS
   ISERROR=$ISERROR
   
   More in $websiteBACKUP/$websiteCopyLOG.
   Your script, $BASH_SOURCE" | mail -s $websiteCopyLOG $mailTo
fi
