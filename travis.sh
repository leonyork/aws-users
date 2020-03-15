#!/usr/bin/env sh
#######################################################################
# Update travis with new AWS credentials
# The first argument should be the json response to create-access-key
# The second argument should be the repo to update
#######################################################################
set -e

if [ -z "$1" ]
then
    echo "You must specify the json response to create-access-key"
    exit 1
fi

if [ -z "$2" ]
then
    echo "You must specify the repo to update"
    exit 1
fi

apk add --no-cache jq > /dev/null

ACCESS_KEY_ID=`echo $1 | jq -j .AccessKeyId`
SECRET_ACCESS_KEY=`echo $1 | jq -j .SecretAccessKey`

travis env --com --no-interactive --repo $2 --private set AWS_ACCESS_KEY_ID $ACCESS_KEY_ID
travis env --com --no-interactive --repo $2 --private set AWS_SECRET_ACCESS_KEY $SECRET_ACCESS_KEY
travis env --com --no-interactive --repo $2 --public set ENV_UPDATED "`date`"