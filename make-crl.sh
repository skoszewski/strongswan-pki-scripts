#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

# Check if the base CRL exists
if [ ! -f $CACRL ]
then
    # The base CRL must be created after the CA.
    echo "ERROR: CA CRL file does not exist."
    exit 1
fi

if pki --signcrl --cacert $CACERT --cakey $CAKEY --digest sha256 --lifetime 31 --lastcrl $CACRL > $CACRL.new
then
    mv $CACRL $CACRL.old
    mv $CACRL.new $CACRL
else
    echo "ERROR: Cannot create a new CRL file."
    exit 1
fi

# Show the current CRL
openssl crl -noout -text -in $CACRL -inform DER
