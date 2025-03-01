#!/bin/bash

# variables
start_m=`date +%M`
start_s=`date +%S`
now=$(date +"%m_%d_%Y-%H_%M")

src_filename="audio_design_backup"
source_dir="/volume1/syncthing/audio/audio_sound_design"
backup_dir="/volume1/backups/audio/audio_sound_design"
num_backups_to_keep=2


LOGFILE="${backup_dir}/${now}_${src_filename}_Log.txt"
echo "Script start: $start_m:$start_s" >> $LOGFILE 2>%1

echo "Compressing and backing up ${src_filename} at ${source_dir}" >> $LOGFILE 2>%1
cd ${source_dir}
#tar -czf - Application\ Support/ -P | pv -s $(du -sb Application\ Support/ | awk '{print $1}') | gzip > $backup_dir/${now}_${src_filename}.tar.gz
#tar -czf $backup_dir/${now}_${src_filename}.tar.gz "${source_dir}"
7z a $backup_dir/${now}_${src_filename}.7z "${source_dir}" -p"password" -mx=1 -t7z -m0=lzma2 


# Get the number of files in the backup directory
num_files=`ls $backup_dir/*_${src_filename}.7z | wc -l`
echo "Number of files in directory: $num_files" >> $LOGFILE 2>%1
# Get the full path of the oldest file in the directory
oldest_file=`ls -t $backup_dir/*_${src_filename}.7z | tail -1`
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
  echo "${src_filename} Backup completed in $runtime" >> $LOGFILE 2>%1
else
  echo "${src_filename} Backup failed. See log for more details." >> $LOGFILE 2>%1
fi
