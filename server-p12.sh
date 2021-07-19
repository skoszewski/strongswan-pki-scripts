#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

# Set certificate and key location
CERTDIR=$CAROOT/servers

# Parse the first argument as a certificate name.
NAME="${1:?ERROR: Certificate file name is missing.}"

BASENAME="$(echo $NAME | sed 's/\..*//g')"

# Build certificate, key and PKCS#12 file path names
CERTPATH="$CERTDIR/${BASENAME}.pem"
KEYPATH="$CERTDIR/${BASENAME}-key.pem"
P12NAME="${BASENAME}.p12"
P12PATH="$CERTDIR/${P12NAME}"
PASSPATH="$CERTDIR/${BASENAME}.pass"

# Check if the certificate exists
if [ ! -f $CERTPATH ]
then
    echo "ERROR: The certificate file at \"$CERTPATH\" does not exist."
    exit 1
fi

# Check if the key exists
if [ ! -f $KEYPATH ]
then
    echo "ERROR: The key file at \"$KEYPATH\" does not exist."
    exit 1
fi

read -p "Do you want to provide you own export password for the PCKS#12 file? " ans

if echo $ans | grep -q '^[yY]'
then
    openssl pkcs12 -export -in $CERTPATH -inkey $KEYPATH -certfile $CACERT -name "$BASENAME" -out $P12PATH
else
    if [ -f $PASSPATH ]; then rm -f $PASSPATH; fi
    touch $PASSPATH
    chmod 0600 $PASSPATH
    openssl rand 12 | base64 >> $PASSPATH
    openssl pkcs12 -export -in $CERTPATH -inkey $KEYPATH -certfile $CACERT -passout file:$PASSPATH -name "$BASENAME" -out $P12PATH

    echo "The password for $P12NAME is \"$(cat $PASSPATH)\"."
    echo ""
fi

chmod 0644 $P12PATH
pki --pkcs12 --list --in $P12PATH
