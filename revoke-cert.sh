#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

CERTPATH="$1"
REASON="${2:-superseded}"

# Valid reasons are: key-compromise, ca-compromise, affiliation-changed, superseded, cessation-of-operation, certificate-hold
case $REASON in
    key-compromise|ca-compromise|affiliation-changed|superseded|cessation-of-operation|certificate-hold)
        ;;
    *)
        echo "ERROR: Reason \"$REASON\" is not supported."
        exit 1
esac

# Check if the file exists
if [ ! -f "$CERTPATH" ]
then
    echo "ERROR: The file \"$CERTPATH\" does not exist or is unreadable."
    exit 1
fi

# Try to revoke the certificate
if [ ! -f $CACRL ]
then
    echo "ERROR: CA CRL file does not exist."
    exit 1
fi

CERTSERIAL=$(openssl x509 -noout -serial -in $CERTPATH|sed 's/^serial=//')

echo "The certificate: $(openssl x509 -noout -subject -in $CERTPATH|sed 's/^subject=//')"
echo "with the serial number: $CERTSERIAL"
echo "issued on $(openssl x509 -noout -startdate -in $CERTPATH|sed 's/^notBefore=//') will be revoked."

read -p "Are you sure? " ans

if ! echo $ans | grep -q '^[yY]'
then
    exit 0
fi

# Try to revoke the certificate
if pki --signcrl --cacert $CACERT --cakey $CAKEY --digest sha256 --lifetime 31 --lastcrl $CACRL --reason $REASON --cert $CERTPATH > $CACRL.new
then
    mv $CACRL $CACRL.old
    mv $CACRL.new $CACRL
else
    echo "ERROR: Cannot create a new CRL file. The certificate has not been revoked."
    exit 1
fi

# Show the new CRL
pki --print --type crl --in $CACRL

# Archive the certificate file using the revocation date and certificate serial number as a new name.
cp $CERTPATH $CAROOT/revoked/$(date "+%Y%m%d")-$CERTSERIAL.pem

# Remove PFX and password file.
if [ -f $CERTDIR/${BASENAME}.p12 ]
then
    rm $CERTDIR/${BASENAME}.p12
fi

if [ -f $CERTDIR/${BASENAME}.txt ]
then
    rm $CERTDIR/${BASENAME}.txt
fi

# Remove certificate files
CERTDIR=$(dirname $CERTPATH)
BASENAME=$(basename $CERTPATH .pem)
KEYPATH=${CERTDIR}/${BASENAME}-key.pem

if ! rm $CERTPATH $KEYPATH
then
    echo "WARNING: Certificate file or key file or both were not removed."
fi
