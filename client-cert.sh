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
PASSPATH="$CERTDIR/${BASENAME}.pass"
P12NAME="${BASENAME}.p12"
P12PATH="$CERTDIR/${P12NAME}"

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
if [ -f $KEYPATH ]; then rm -f $KEYPATH; fi
touch $KEYPATH
chmod 0600 $KEYPATH
pki --gen --outform pem >> $KEYPATH
pki --issue --cacert $CACERT --cakey $CAKEY --in $KEYPATH --type priv --dn "E=$EMAIL,CN=$CN${CADNSUFFIX}" --flag clientAuth --crl $CRLURI --lifetime $(($CACLIYRS * 365)) --outform pem --digest sha256 > $CERTPATH
echo "done."

read -p "Do you want to provide you own export password for the PCKS#12 file? " ans

if echo $ans | grep -q '^[yY]'
then
    openssl pkcs12 -export -in $CERTPATH -inkey $KEYPATH -certfile $CACERT -name "$CN" -out $P12PATH
else
    if [ -f $PASSPATH ]; then rm -f $PASSPATH; fi
    touch $PASSPATH
    chmod 0600 $PASSPATH
    openssl rand 12 | base64 >> $PASSPATH
    openssl pkcs12 -export -in $CERTPATH -inkey $KEYPATH -certfile $CACERT -passout file:$PASSPATH -name "$CN" -out $P12PATH
    chmod 0644 $P12PATH

    echo "The password for $P12NAME is \"$(cat $PASSPATH)\"."
    echo ""
fi

pki --print --in $CERTPATH
echo ""

pki --pkcs12 --list --in $PASSPATH
