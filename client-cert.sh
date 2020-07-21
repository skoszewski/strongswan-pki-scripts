#!/usr/bin/env sh

if [ -z "$CAROOT" ]
then
    # CA root location is not defined, bail-out.
    echo "ERROR: CAROOT is not set."
    exit 1
fi

# Set certificate and key location
CERTDIR=$CAROOT/clients

# Parse arguments: Common Name and Email
CN="${1:?ERROR: Common name not specified.}"
EMAIL="${2:?ERROR: E-mail not specified.}"

# Remove dots and convert '@' to '-at-'.
BASENAME=$(echo $EMAIL | sed 's/\./_/g' | sed 's/@/-at-/')

# Build certificate and key path names
CERTPATH="$CERTDIR/${BASENAME}.pem"
KEYPATH="$CERTDIR/${BASENAME}-key.pem"

if [ -f $CERTPATH ]
then
    echo "ERROR: The certificate with the same name already exists. Please revoke it and remove or change the name."
    exit 1
fi

echo "A certificate will be issued for: \"$CN\" with E-mail: \"$EMAIL\""
echo "It will be saved in \"$CERTDIR\" directory with the name \"${BASENAME}.pem\"."
echo ""

read -p "Are you sure, you want to issue the certificate? " ans

if ! echo $ans | grep -q '^[yY]'
then
    exit 0
fi

echo -n "Generating key pair and the certificate..."
pki --gen --outform pem > $KEYPATH
pki --issue --cacert $CACERT --cakey $CAKEY --in $KEYPATH --type priv --dn "E=$EMAIL,CN=$CN${CADNSUFFIX}" --flag clientAuth --crl $CRLURI --outform pem --digest sha256 > $CERTPATH
echo "done."

openssl rand 12 | base64 > $CERTDIR/$BASENAME.txt
openssl pkcs12 -export -in $CERTPATH -inkey $KEYPATH -certfile $CACERT -passout file:$CERTDIR/$BASENAME.txt -name "$CN" -out $CERTDIR/$BASENAME.p12
echo "The password for $BASENAME.p12 is \"$(cat $CERTDIR/$BASENAME.txt)\"."
echo ""
pki --print --in $CERTPATH
echo ""
echo "You will be asked to enter the following password: \"$(cat $CERTDIR/$BASENAME.txt)\""
pki --pkcs12 --list --in $CERTDIR/$BASENAME.p12
