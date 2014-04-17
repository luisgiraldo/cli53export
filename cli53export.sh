#!/bin/bash
# written by Tomas Nevar (http://www.lisenet.com)
# v2 by Luis Giraldo (http://ook.co)
# requires cli53 - https://github.com/barnybug/cli53
# requires s3cmd - https://github.com/s3tools/s3cmd

DATESTAMP=`date +%Y%m%d-%H%M`
BACKUPPATH="/tmp/route53backups"
ARCHIVEPATH="/tmp/route53archives"
ZONESFILE="all-zones.txt"
DOMAINSFILE="all-domains.txt"

# replace the s3 path below with your bucket name and subfolder path, if necessary
S3BUCKET="s3://bucketname/subfolder"

mkdir -p "$BACKUPPATH"
mkdir -p "$ARCHIVEPATH"
cd "$BACKUPPATH"

# get a list of all hosted zones
cli53 list > "$ZONESFILE"  2>&1

# get a list of domain names only
sed '/Name:/!d' "$ZONESFILE"|cut -d: -f2|sed 's/^.//'|sed 's/.$//' > "$DOMAINSFILE"

# create backup files for each domain
while read -r line; do
        echo "Backing up zone file for $line..."
        cli53 export --full "$line" > "$line.zone.txt"
done < "$DOMAINSFILE"

# create an archive to put on S3
cd "$ARCHIVEPATH"
tar cvfz "route53backup-$DATESTAMP.tgz" "$BACKUPPATH"

# copy archive to S3
s3cmd put route53backup-$DATESTAMP.tgz $S3BUCKET

# clean up
rm -rf "$BACKUPPATH"
rm -rf "$ARCHIVEPATH"

exit 0