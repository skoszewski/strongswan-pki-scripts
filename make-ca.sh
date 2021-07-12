#!/usr/bin/env sh

# Get CA information from the command line arguments
CAROOT="${1:-/config/user-data/CA}"

# Ask for additional information
read -p "Common Name       : " uCN
read -p "Email Address     : " uE
read -p "Organization      : " uORG
read -p "Organization Unit : " uOU
read -p "Locality          : " uL
read -p "State             : " uST
read -p "Country           : " uC

# Define initial configuration
CANAME="${uCN:-Custom CA $(date +%Y%m%d)}"

# Define CA certificate DN
CADN=""

if [ ! -z "$uE" ]
then
    CADN="$CADN,E=$uE"
fi

if [ ! -z "$uORG" ]
then
    CADN="$CADN,O=$uORG"
fi

if [ ! -z "$uOU" ]
then
    CADN="$CADN,OU=$uOU"
fi

if [ ! -z "$uL" ]
then
    CADN="$CADN,L=$uL"
fi

if [ ! -z "$uST" ]
then
    CADN="$CADN,ST=$uST"
fi

if [ ! -z "$uC" ]
then
    CADN="$CADN,C=$uC"
fi

if [ ! -d $CAROOT ]
then
    # using bash-like construct {servers,clients,revoked} may not work on embedded shells
    for d in servers clients revoked
    do
        mkdir -p $CAROOT/$d
    done
else
    # Bail-out if the directory already exists.
    read -p "CA root is found at $CAROOT. Would you like it to be removed? " ans
    
    if echo $ans | grep -q '^[yY]'
    then
        rm -r $CAROOT
        for d in servers clients revoked
        do
            mkdir -p $CAROOT/$d
        done
    else
        echo "The current CA has not been modified."
        exit 0
    fi
fi

# Convert relative path to absolute
CAROOT="$(cd $CAROOT; pwd)"

# Create env.sh file. Remove the email from DN suffix appended to each certificate DN.
cat >$CAROOT/env.sh <<ENDOFENV
export CAROOT=/config/user-data/CA
export CANAME="$CANAME"
export CADNSUFFIX="$(echo $CADN | perl -pe 's/,E=.*?,/,/')"
export CAKEY=\$CAROOT/caKey.pem
export CACERT=\$CAROOT/caCert.pem
export CACRL=\$CAROOT/crl.pem
export CRLURI=http://www.koszewscy.waw.pl/crl.pem
ENDOFENV

# Source the environment, don't use bash'es `source` command
. $CAROOT/env.sh

# Generate CA private key
pki --gen --outform pem > $CAKEY

# Issue a self signed CA certificate
pki --self --in $CAKEY --dn "CN=$CANAME$CADN" --ca --lifetime 3650 --outform pem > $CACERT

# Create a base revocation list (empty for now)
pki --signcrl --cacert $CACERT --cakey $CAKEY --digest sha256 --lifetime 31 > $CACRL

# Print the resulting certificate
echo ""
echo "CA certificate created."
echo ""
pki --print --in $CACERT
