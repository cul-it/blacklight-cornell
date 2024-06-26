#!/usr/bin/env bash

# APP_VERSION=${APP_VERSION}

WORKDIR="/blacklight-cornell"
cd $WORKDIR

MOUNT_PT="/custom_mnt"
MNT_CRED="${MOUNT_PT}/credentials"
if [ -f "$MNT_CRED" ]; then
    echo "Supplied aws credentials will be used"
    HOME_DIR=~
    HOME_EXPAND_PATH=$(eval echo $HOME_DIR)
    cp $MNT_CRED $(echo $HOME_EXPAND_PATH/.aws/credentials)
fi
# Should we delete the cred file otherwise?
# When running as container, we will never use this file

MNT_ENVFILE="${MOUNT_PT}/.env"
ENVFILE="${WORKDIR}/.env"
if [ -f "$MNT_ENVFILE" ]; then
    echo "Supplied .env file will be used"
    cp $MNT_ENVFILE $ENVFILE
else
    ruby get_env.rb $APP_VERSION $ENVFILE
fi
