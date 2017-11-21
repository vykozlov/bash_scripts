# bash_scripts
Place for various bash scripts

### backup_dir.sh:

 Script to backup a remote directory (e.g. website). Executed typically every day by cronjob in Linux.
 Backup is incremental:
 History is kept of every weekday for one week, and for 1st and 15th day of a month.

 Important is `-al` option of `cp`! i.e. we use 'hardlinks' to save space.

'Simplified' version, meaning directories
  * backup.now
  * backup.1
  * backup.15
  * backup.wday1..7
  
 have to be manually created beforehand     
