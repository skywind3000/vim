#! /bin/sh

CLOUD_USER=""
CLOUD_PASS=""
CLOUD_HOME="${HOME}/document/cloud/owncloud"
CLOUD_HTTP="https://xxx.xxx.com/owncloud"
CLOUD_SLEEP=60

CloudSync() {
	/usr/bin/owncloudcmd -u ${CLOUD_USER} -p ${CLOUD_PASS} \
		--trust --silent --exclude /dev/null \
		--non-interactive ${CLOUD_HOME} ${CLOUD_HTTP}
}


while [ 1 ]
do
	echo "Starting sync: ${CLOUD_HOME}"
	CloudSync
	sleep "${CLOUD_SLEEP}"
done

