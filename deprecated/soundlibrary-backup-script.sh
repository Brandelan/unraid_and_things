#!/bin/bash

# variables
start_m=`date +%M`
start_s=`date +%S`
now=$(date +"%m_%d_%Y-%H_%M")

LOGFILE="/volume1/backups/audio/SoundLibrary/${now}_Log.txt"
echo "Script start: $start_m:$start_s" >> $LOGFILE 2>%1

source_dir="/volume1/syncthing/audio/audio_sound_library/"
backup_dir="/volume1/backups/audio/SoundLibrary"
num_backups_to_keep=2

echo "Compressing and backing up sound library audio at ${source_dir}" >> $LOGFILE 2>%1
cd ${source_dir}
#tar -czf - Application\ Support/ -P | pv -s $(du -sb Application\ Support/ | awk '{print $1}') | gzip > $backup_dir/wiki_backup_$now.tar.gz
7z a $backup_dir/${now}_soundlibrary_backup.7z "${source_dir}" -p"password" -mx=1 -t7z -m0=lzma2 
#tar -czf $backup_dir/${now}_soundlibrary_backup.tar.gz "${source_dir}"


# Get the number of files in the backup directory
num_files=`ls $backup_dir/*_soundlibrary_backup.7z | wc -l`
echo "Number of files in directory: $num_files" >> $LOGFILE 2>%1
# Get the full path of the oldest file in the directory
oldest_file=`ls -t $backup_dir/*_soundlibrary_backup.7z | tail -1`
echo $oldest_file >> $LOGFILE 2>%1

# After the backup, if the number of files is larger than the number of backups we want to keep
# remove the oldest backup file
if (($num_files > $num_backups_to_keep));
then
    echo "Removing file: $oldest_file" >> $LOGFILE 2>%1
    rm $oldest_file
fi


# REMOVE THE OLDEST LOG FILES
num_files=`ls $backup_dir/*_Log.txt | wc -l`
echo "Number of files in directory: $num_files" >> $LOGFILE 2>%1
# Get the full path of the oldest file in the directory
oldest_file=`ls -t $backup_dir/*_Log.txt | tail -1`
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
# Push a notification to the Unraid GUI if the backup failed of passed
if [[ $? -eq 0 ]]; then
  echo "SoundLibrary Audio Backup completed in $runtime" >> $LOGFILE 2>%1
else
  echo "SoundLibrary Audio Backup failed. See log for more details." >> $LOGFILE 2>%1
fi
