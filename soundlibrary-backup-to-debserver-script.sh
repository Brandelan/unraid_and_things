#!/bin/bash

# variables
start_m=`date +%M`
start_s=`date +%S`
now=$(date +"%m_%d_%Y-%H_%M")

logfile_dir="/volume2/backups/audio/logs/soundlibrary_rsync"
LOGFILE="/volume2/backups/audio/logs/soundlibrary_rsync/${now}_Log.txt"
echo "Script start: $start_m:$start_s" >> $LOGFILE 2>%1

source_dir="/volume2/backups/audio/SoundLibrary/"
backup_dir="brandelan@10.0.0.95:/home/brandelan/backups/soundlibrary"
num_backups_to_keep=2

echo "rsync-ing sound library audio at ${source_dir}" >> $LOGFILE 2>%1

sudo rsync -aP --delete "$source_dir" "$backup_dir" & RSYNC_PID=$!

#wait for the rsync process to finish and capture its output
wait "$RSYNC_PID"
EXIT_STATUS=$?

if [ "$?" -eq "0" ]
then
    echo "* Downloading Complete" >> $LOGFILE 2>%1
    echo "* Downloading Complete"
else
    echo "* Downloading Failed" >> $LOGFILE 2>%1
    echo "* Downloading Failed"
fi


# REMOVE THE OLDEST LOG FILES
num_files=`ls $logfile_dir/*_Log.txt | wc -l`
echo "Number of files in directory: $num_files" >> $LOGFILE 2>%1
# Get the full path of the oldest file in the directory
oldest_file=`ls -t $logfile_dir/*_Log.txt | tail -1`
echo $oldest_file >> $LOGFILE 2>%1

# After the backup, if the number of files is larger than the number of backups we want to keep
# remove the oldest backup file
if (($num_files > $num_backups_to_keep));
then
    echo "Removing file: $oldest_file" >> $LOGFILE 2>%1
    rm $oldest_file
fi


end_m=`date +%M`
end_s=`date +%S`
echo "Script end: $end_m:$end_s" >> $LOGFILE 2>%1

runtime_m=$((end_m-start_m))
runtime_s=$((end_s-start_s))
echo "Script runtime: $runtime_m:$runtime_s" >> $LOGFILE 2>%1
echo "SoundLibrary Audio Backup scripot completed in $runtime" >> $LOGFILE 2>%1

