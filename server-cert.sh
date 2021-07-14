#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

# Set certificate and key location
CERTDIR=$CAROOT/servers

# Parse the first argument as a main DNS FQDN
NAME="${1:?ERROR: Server DNS name is missing.}"

# Strip the domain part from the FQDN
BASENAME="$(echo $NAME | sed 's/\..*//g')"

# Build certificate and key path names
CERTPATH="$CERTDIR/${BASENAME}.pem"
KEYPATH="$CERTDIR/${BASENAME}-key.pem"

if [ -f $CERTPATH ]
then
    echo "ERROR: The certificate with the same name already exists. Please revoke it and remove or change the name."
    exit 1
fi

SAN_OPTIONS="--san \"${NAME}\""
FQDNS=""

# Process additional arguments as additional SANs
shift

while [ ! -z "$1" ]
do
    SAN_OPTIONS="$SAN_OPTIONS --san \"$1\""
    if [ -z "$FQDNS" ]
    then
        FQDNS="$1"
    else
        FQDNS="$FQDNS $1"
    fi
    shift
done

echo "A certificate will be issued for the FQDN: $NAME"
echo "It will be saved in \"$CERTDIR\" directory with the name \"${BASENAME}.pem\"."
echo ""
if [ "$FQDNS" ]
then
    echo "The additional subject alternative names are: $FQDNS"
    echo ""
fi

read -p "Are you sure, you want to issue the certificate? " ans

if ! echo $ans | grep -q '^[yY]'
then
    exit 0
fi

echo -n "Generating key pair and the certificate..."
pki --gen --outform pem > $KEYPATH
chmod 0600 $KEYPATH
pki --issue --cacert $CACERT --cakey $CAKEY --in $KEYPATH --type priv --dn "CN=${NAME}${CADNSUFFIX}" $SAN_OPTIONS --flag serverAuth --flag clientAuth --crl $CRLURI --lifetime $(($CASRVYRS * 365)) --outform pem --digest sha256 > $CERTPATH
echo "done."

# Print the certificate information
pki --print --in $CERTPATH
