#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

# Check if the CA has been already initialized
if [ ! -f $CAROOT/caCert.pem ]
then
    # Generate CA private key
    pki --gen --outform pem > $CAKEY

    # Secure the key
    chmod 0600 $CAKEY

    # Issue a self signed CA certificate
    pki --self --in $CAKEY --dn "CN=$CANAME$CADNSUFFIX" --ca --lifetime $(($CACRTYRS * 365)) --outform pem > $CACERT

    # Create a base revocation list (empty for now)
    pki --signcrl --cacert $CACERT --cakey $CAKEY --digest sha256 --lifetime $CACRLLIFE > $CACRL

    # Print the resulting certificate
    echo "CA certificate created."
    echo ""
    pki --print --in $CACERT
else
    echo "The CA has already been initialized. Re-run init-ca.sh script to remove it or create another one."
    exit 0
fi
