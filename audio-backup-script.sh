#!/bin/bash

# variables
start_m=`date +%M`
start_s=`date +%S`
now=$(date +"%m_%d_%Y-%H_%M")

LOGFILE="/volume2/backups/docker/syncthing/audio/${now}_Log.txt"
echo "Script start: $start_m:$start_s" >> $LOGFILE 2>%1

source_dir="/volume2/backups/syncthing/audio/"
backup_dir="/volume2/backups/docker/syncthing/audio"
num_backups_to_keep=2

# Stop the container
docker stop syncthing
echo "Stopping syncthing" >> $LOGFILE 2>%1

# wait 30 seconds
sleep 30

# Get the state of the docker
container_running=`docker inspect -f '{{.State.Running}}' syncthing`
echo "syncthing running: $container_running" >> $LOGFILE 2>%1

# If the container is still running retry 5 times
fail_counter=0
while [ "$container_running" = "true" ];
do
    fail_counter=$((fail_counter+1))
    docker stop syncthing
    echo "Stopping syncthing attempt #$fail_counter" >> $LOGFILE 2>%1
    sleep 30
    container_running=`docker inspect -f '{{.State.Running}}' syncthing`
    # Exit with an error code if the container won't stop
    # Restart syncthing and report a warning to the Unraid GUI
    if (($fail_counter == 5));
    then
        echo "syncthing failed to stop. Restarting container and exiting" >> $LOGFILE 2>%1
        docker start syncthing
        echo "syncthing Backup failed. Failed to stop container for backup." >> $LOGFILE 2>%1
        exit 1
    fi
done

# Once the container is stopped, backup the Application Support directory and restart the container
# The tar command shows progress
if [ "$container_running" = "false" ]
then
    echo "Compressing and backing up syncthing audio at ${source_dir}" >> $LOGFILE 2>%1
    cd ${source_dir}
    #tar -czf - Application\ Support/ -P | pv -s $(du -sb Application\ Support/ | awk '{print $1}') | gzip > $backup_dir/wiki_backup_$now.tar.gz
    tar -czf $backup_dir/${now}_syncthing_audio_backup.tar.gz "${source_dir}"
    echo "Starting syncthing" >> $LOGFILE 2>%1
    docker start syncthing
fi

# Get the number of files in the backup directory
num_files=`ls $backup_dir/*_syncthing_audio_backup.tar.gz | wc -l`
echo "Number of files in directory: $num_files" >> $LOGFILE 2>%1
# Get the full path of the oldest file in the directory
oldest_file=`ls -t $backup_dir/*_syncthing_audio_backup.tar.gz | tail -1`
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
  echo "Syncthing Audio Backup completed in $runtime" >> $LOGFILE 2>%1
else
  echo "Syncthing Audio Backup failed. See log for more details." >> $LOGFILE 2>%1
fi
