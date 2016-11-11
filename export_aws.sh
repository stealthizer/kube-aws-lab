#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "You must specify a valid amazon account from your credentials file"
    break 
else
    account=$1
    account_data=`cat ~/.aws/credentials|grep -A4 $account`
    ACCOUNT_KEY_ID=`echo "$account_data"|grep aws_access_key_id|cut -d= -f2|xargs`
    SECRET_ACCESS_KEY=`echo "$account_data"|grep aws_secret_access_key|cut -d= -f2|xargs`
    export AWS_ACCESS_KEY_ID=$ACCOUNT_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
    # TEST if the exported variables are present
    if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "AWS_SECRET_ACCESS_KEY" ]]; then 
        echo -n "$account credentials exported"
        exit 0
    else 
        echo -n "account variables not set"
        exit 1
    fi
fi
