# mrit_use_backup

This script has two pieces: #1 Running MRIT (MapReduceIndexTool) on inputfiles (with morphline and solr backup) and then restoring the solr backup into a collection.
This is a more efficient way than using the MRIT go-live command, which uses mergeindexes which is synchronous and resource intensive.  Using backup is asynchronous and recommended within CDP (Cloudera Data Platform)
  
A majority of this script is based on Cloudera documentation: https://docs.cloudera.com/cdp-private-cloud-base/7.1.7/search-indexing/topics/search-mrit-backup-format.html 
https://docs.cloudera.com/runtime/7.2.14/search-indexing/topics/search-mrit-backup-format.html

Defined variables below are pointing to CDP PaaS (DataHub Data Discovery and Exploration template), using the YELP data.  As instructed in TODO, replace these variables.  
Parts are detailed within https://github.com/ryancicak/mrit_use_backup 

TODO: Simply replace the variables below with your environment's inputs.  I recommend using a smaller subset of data first to validate your variables work.  
When you execute this script on a cluster with Kerberos enabled, you'll need to run kinit as the user that is calling YARN (yarn jar) and Solr (solrctl)


Part 1 - Delete the files in the output directory that MRIT job will write to

Part 2 - Delete the MRIT log file, which allows a new one to be created when executing MRIT

Part 3 - Executing the MRIT job, using the use-backup-format

Part 4 - Check if the MRIT job was successful (from part 3)

Part 5 - Since the MRIT job was successful, delete the existing collection name (this collection will be restored from the backup)

Part 6 - Since the MRIT job was successful, restore the Solr collection from the backup (async)

Part 7 - Since the MRIT job was successful, check the status of restoring the Solr collection (from part 6), until it's completed
