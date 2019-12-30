#!/usr/bin/env bash

set -e

# create a random passphrase
export GPG_PASSPHRASE=$(echo "$RANDOM$(date)" | md5sum | cut -d\  -f1)

# configuration to generate gpg keys
cat >gen-key-script <<EOF
    %echo Generating a basic OpenPGP key
    Key-Type: RSA
    Key-Length: 4096
    Name-Real: CurrencyFair
    Name-Email: mateuszbajorek@currencyfair.com
    Expire-Date: 0y
    Passphrase: ${GPG_PASSPHRASE}
    %commit
    %echo done
EOF

# create a local keypair with given configuration
gpg --batch --gen-key gen-key-script


# export created GPG key
#
# example output
# sec   4096R/EDD32E8B 2016-09-08 [verfällt: 2018-09-08]
# uid                  Lars K.W. Gohlke <lars.gohlke@idealo.de>
# ssb   4096R/CC1613B2 2016-09-08
# ssb   4096R/55B7CAA2 2016-09-08
export GPG_KEYNAME=$(gpg -K | grep ^\\s | head -n1)

# cleanup local configuration
shred gen-key-script

# publish the gpg key
# (use keyserver.ubuntu.com as travis request keys from this server,
#  we avoid synchronization issues, while releasing)
gpg --keyserver keyserver.ubuntu.com --send-keys ${GPG_KEYNAME}

# check that the key is accessible
mkdir -m 700 ./gpgtest
while(true); do
  date
  GNUPGHOME=./gpgtest gpg --keyserver keyserver.ubuntu.com  --recv-keys ${GPG_KEYNAME} && break || sleep 30
done
if [[-f ./gpgtest/pubring.gpg]]
  echo "Key ${GPG_KEYNAME} uploaded to keyserver.ubuntu.com"
else
  echo "Could not retrieve key ${GPG_KEYNAME} from keyserver.ubuntu.com"
  exit -1
fi
rm -rf ./gpgtest
