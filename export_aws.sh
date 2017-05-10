#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "You must specify a valid amazon account from your credentials file"
    return 
else
    account=$1
    account_data=`cat ~/.aws/credentials|grep -A4 $account`
    ACCOUNT_KEY_ID=`echo "$account_data"|grep aws_access_key_id|cut -d= -f2|xargs`
    SECRET_ACCESS_KEY=`echo "$account_data"|grep aws_secret_access_key|cut -d= -f2|xargs`
    REGION=`echo "$account_data"|grep region|cut -d= -f2|xargs`
    export AWS_ACCESS_KEY_ID=$ACCOUNT_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
    export AWS_DEFAULT_REGION=$REGION
    # TEST if the exported variables are present
    if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "AWS_SECRET_ACCESS_KEY" && ! -z "AWS_DEFAULT_REGION" ]]; then 
        echo -n "$account credentials exported"
    else 
        echo -n "account variables not set"
    fi
fi
