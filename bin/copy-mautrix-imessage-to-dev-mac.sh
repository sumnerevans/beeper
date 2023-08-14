#!/usr/bin/env bash

set -xe

wget -O $HOME/tmp/mautrix-imessage.zip $2
rm -rf $HOME/tmp/mautrix-imessage
unzip $HOME/tmp/mautrix-imessage.zip -d $HOME/tmp/mautrix-imessage

scp $HOME/tmp/mautrix-imessage/mautrix-imessage-amd64/mautrix-imessage ssh-user@$1:mautrix-imessage
ssh ssh-user@$1 'sudo cp $HOME/mautrix-imessage /usr/local/bin/mautrix-imessage'
