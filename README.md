# mrit_use_backup

Part 1 - Delete the files in the output directory that MRIT job will write to

Part 2 - Delete the MRIT log file, which allows a new one to be created when executing MRIT

Part 3 - Executing the MRIT job, using the use-backup-format

Part 4 - Check if the MRIT job was successful (from part 3)

Part 5 - Since the MRIT job was successful, delete the existing collection name (this collection will be restored from the backup)

Part 6 - Since the MRIT job was successful, restore the Solr collection from the backup (async)

Part 7 - Since the MRIT job was successful, check the status of restoring the Solr collection (from part 6), until it's completed
