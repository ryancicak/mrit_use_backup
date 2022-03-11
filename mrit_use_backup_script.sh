#!/bin/bash

# This script has two pieces: #1 Running MRIT (MapReduceIndexTool) on inputfiles (with morphline and solr backup) and then restoring the solr backup into a collection
# This is a more efficient way than using the MRIT go-live command, which uses mergeindexes which is synchronous and resource intensive.  Using backup is asynchronous and recommended within CDP (Cloudera Data Platform)
#  
# A majority of this script is based on Cloudera documentation: https://docs.cloudera.com/cdp-private-cloud-base/7.1.7/search-indexing/topics/search-mrit-backup-format.html 
# https://docs.cloudera.com/runtime/7.2.14/search-indexing/topics/search-mrit-backup-format.html
#
# Defined variables below are pointing to CDP PaaS (DataHub Data Discovery and Exploration template), using the YELP data.  As instructed in TODO, replace these variables.  
# Parts are detailed within https://github.com/ryancicak/mrit_use_backup 
#
# TODO: Simply replace the variables below with your environment's inputs.  I recommend using a smaller subset of data first to validate your variables work.  
# When you execute this script on a cluster with Kerberos enabled, you'll need to run kinit as the user that is calling YARN (yarn jar) and Solr (solrctl)
#
# Generate an UUID that we'll use later to track the Solr backup command (which is async)
UUID=$(uuidgen)
MRIT_OUTPUT_FOLDER=results
MRIT_LOG_FILE=/tmp/mrit_log_file.txt
DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`

# Variables that should be overwritten (plug-and-play)
jaas_location=/root/jaas.conf
queue_name=default
nn_fqdn=hdfs://namenodeserver0.cicak.a465-9q4k.cloudera.site:8020
input_file_folder=/tmp/inputfiles
mrit_output_dir=/user/rcicak/outdir
morphline=/tmp/reviews.conf
zk=zookeeper0.cicak.a465-9q4k.cloudera.site:2181,zookeeper1.cicak.a465-9q4k.cloudera.site:2181,zookeeper2.cicak.a465-9q4k.cloudera.site:2181/solr-dde
collection_name=reviews
backup_name=reviews_backup

#STARTING
echo "Starting the MRIT job with use-backup-format at $DATE_WITH_TIME"

# Part 1
echo "Delete the output directory that the MRIT job will write to"
hdfs dfs -rm -r -skipTrash $nn_fqdn$mrit_output_dir*

# Part 2
echo "Delete the MRIT log file, starting a new one when executing MRIT"
rm -f $MRIT_LOG_FILE

# Part 3
YARN_OPTS="-Djava.security.auth.login.config=/root/$jaas_location" yarn jar /opt/cloudera/parcels/CDH/lib/solr/contrib/mr/search-mr-*-job.jar org.apache.solr.hadoop.MapReduceIndexerTool -D 'mapred.child.java.opts=-Xmx8g' -D mapred.job.queue.name=$queue_name --log4j /opt/cloudera/parcels/CDH/share/doc/search*/examples/solr-nrt/log4j.properties --morphline-file $morphline --output-dir  $nn_fqdn$mrit_output_dir --verbose --zk-host $zk --collection $collection_name --use-backup-format --backup-name $backup_name $nn_fqdn$input_file_folder > $MRIT_LOG_FILE

echo "Checking if the MRIT job was successful"

# Part 4
if grep -q "Success. Done. Program" $MRIT_LOG_FILE; then

	# Part 5
	echo "MRIT completed successfully! Proceeding with Solr collection commands"
	echo "Deleting the collection $collection_name, we'll be restoring from backup shortly"
	solrctl --zk $zk collection --delete $collection_name

 	# Part 6
	echo "Restoring the collection $collection_name from backup $backup_name.  This is an async command, therefore, we'll check status next..."
	solrctl --zk $zk collection --restore $collection_name -b $backup_name -l $mrit_output_dir/$MRIT_OUTPUT_FOLDER -i $UUID

	# Part 7
	while true; do
		if solrctl --zk $zk collection --request-status $UUID | grep -q "completed"; then
			echo "The restore on collection $collection_name from backup $backup_name is successful!"
			echo "The UUID of the successful collection restore job is $UUID"
			echo "Completed at "+`date "+%Y%m%d-%H%M%S"`
			break
		else
			echo "The restore on collection $collection_name from backup $backup_name is not yet successful, waiting on job $UUID..."
			echo "While waiting for the restore to finish, sleep for 5 seconds"
			sleep 5
		fi
	done
else
	echo "The MRIT job failed!  Please look at the log file $MRIT_LOG_FILE for more details, and open a support case with Cloudera."
fi
