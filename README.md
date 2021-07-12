# Strongswan PKI Scripts

A set of scripts designed to help building a simple CA.

## Prerequisities

On Ubuntu 18.04 install StrongSwan PKI package:

```shell
sudo apt -y install strongswan-pki
```

The `pki` command is already available on **EdgeOS** routers.

## CA Initialization

Run the `make-ca.sh` script to initializa the CA storage. The script suite will use a directory for key and certificate storage.

```shell
sh <scripts_directory_name>/make-ca.sh <directory_name>
```

> NOTE: You can omit the directory name and the script will default to use **EdgeOS** `/config/user-data/CA` configuration filesystem area.

An example script call-out:
```text
$ make-ca.sh example-ca
Common Name       : Example CA
Email Address     : pki@example.com
Organization      : Example Corp.
Organization Unit : IT
Locality          : New York City
State             : New York
Country           : US
CA CRL URL        : https://www.example.com/crl.pem

CA certificate created.

  subject:  "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  issuer:   "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  validity:  not before Jul 12 11:08:17 2021, ok
             not after  Jul 10 11:08:17 2031, ok (expires in 3650 days)
  serial:    76:ce:99:d4:b1:e3:fa:f0
  flags:     CA CRLSign self-signed
  subjkeyId: 7a:90:a7:ef:f6:24:4a:61:0e:17:ad:4f:2f:a3:a2:26:07:84:8b:55
  pubkey:    RSA 2048 bits
  keyid:     4f:70:a1:fe:f8:f4:01:1d:a3:94:b1:32:15:19:6f:e0:35:96:8b:47
  subjkey:   7a:90:a7:ef:f6:24:4a:61:0e:17:ad:4f:2f:a3:a2:26:07:84:8b:5
  ```

  The directory contents:

  ```text
  $ ls -l example-ca/
total 8
-rw-r--r-- 1 ubuntu ubuntu 1419 Jul 12 11:08 caCert.pem
-rw-r--r-- 1 ubuntu ubuntu 1679 Jul 12 11:08 caKey.pem
drwxr-xr-x 1 ubuntu ubuntu 4096 Jul 12 11:08 clients
-rw-r--r-- 1 ubuntu ubuntu  531 Jul 12 11:08 crl.pem
-rw-r--r-- 1 ubuntu ubuntu  267 Jul 12 11:08 env.sh
drwxr-xr-x 1 ubuntu ubuntu 4096 Jul 12 11:08 revoked
drwxr-xr-x 1 ubuntu ubuntu 4096 Jul 12 11:08 servers
```

The `env.sh` contents:

```shell
export CAROOT=/home/ubuntu/example-ca
export CANAME="Example CA"
export CADNSUFFIX=",O=Example Corp.,OU=IT,L=New York City,ST=New York,C=US"
export CAKEY=$CAROOT/caKey.pem
export CACERT=$CAROOT/caCert.pem
export CACRL=$CAROOT/crl.pem
export CRLURI=https://www.example.com/crl.pem
```

Copy the `crl.pem` file to the Web location specified.

## Using the CA

Initialize the CA shell environment variables by sourcing the created `env.sh` file.

```shell
$ . example-ca/env.sh
```

### Server certificates

Use the `server-cert.sh` script to create server certficates.

```shell
$ <pki-scripts>/server-cert.sh <fqdn-name> <alternative-fqdn-1> <alternative-fqdn-2> ...
```

An example:

```shell
$ <pki-scripts>/server-cert.sh www.example.com ftp.example.com mail.example.com example.com
```

and output:

```text
$ server-cert.sh www-server1.example.com  www.example.com ftp.example.com mail.example.com example.com
A certificate will be issued for the FQDN: www-server1.example.com
It will be saved in "/home/ubuntu/example-ca/servers" directory with the name "www-server1.pem".

The additional subject alternative names are: www.example.com ftp.example.com mail.example.com example.com

Are you sure, you want to issue the certificate? y
Generating key pair and the certificate...done.
  subject:  "CN=www-server1.example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  issuer:   "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  validity:  not before Jul 12 11:40:00 2021, ok
             not after  Jul 12 11:40:00 2023, ok (expires in 730 days)
  serial:    1a:02:93:d0:86:09:0a:49
  altNames:  "www-server1.example.com", "www.example.com", "ftp.example.com", "mail.example.com", "example.com"
  flags:     serverAuth clientAuth
  CRL URIs:  https://www.example.com/crl.pem
  authkeyId: a4:4e:33:63:63:58:c7:4f:0b:52:51:b5:70:8f:80:19:d9:6a:09:fc
  subjkeyId: 6c:e3:6c:74:02:01:26:95:92:fe:22:89:e7:7f:04:8a:07:02:d6:51
  pubkey:    RSA 2048 bits
  keyid:     44:73:ec:d5:7a:a6:0c:e2:a5:d1:18:34:a2:ef:c7:c9:2c:b7:26:8a
  subjkey:   6c:e3:6c:74:02:01:26:95:92:fe:22:89:e7:7f:04:8a:07:02:d6:51
```

The script will create an unencrypted private key file and a certificate file.

### Client certificates

Use the `client-cert.sh` script to create client certificates.

```shell
$ <pki-scripts>/client-cert.sh <common-name> <e-mail>
```

An example:

```shell
$ <pki-scripts>/client-cert.sh "John Smith" "j.smith@example.com"
```

and output:

```text
$ <pki-scripts>/client-cert.sh "John Smith" "j.smith@example.com"
A certificate will be issued for: "John Smith" with E-mail: "j.smith@example.com"
It will be saved in "/home/slawek/example-ca/clients" directory with the name "j_smith-at-example_com.pem".

Are you sure, you want to issue the certificate? y
Generating key pair and the certificate...done.
Do you want to provide you own export password for the PCKS#12 file? y
Enter Export Password: ********
Verifying - Enter Export Password: ********
  subject:  "E=j.smith@example.com, CN=John Smith, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  issuer:   "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  validity:  not before Jul 12 11:56:24 2021, ok
             not after  Jul 11 11:56:24 2024, ok (expires in 1094 days)
  serial:    09:f4:7f:ac:2c:39:32:c5
  flags:     clientAuth
  CRL URIs:  https://www.example.com/crl.pem
  authkeyId: a4:4e:33:63:63:58:c7:4f:0b:52:51:b5:70:8f:80:19:d9:6a:09:fc
  subjkeyId: 6c:af:bf:62:06:c1:35:34:dc:85:61:61:9a:ec:78:9b:37:18:93:04
  pubkey:    RSA 2048 bits
  keyid:     97:98:4f:04:11:cf:42:b5:b5:91:9d:d1:4d:ae:17:0c:ac:58:66:e3
  subjkey:   6c:af:bf:62:06:c1:35:34:dc:85:61:61:9a:ec:78:9b:37:18:93:04

Private key passphrase:
Certificates:
[ 1] "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US" (CA)
[ 2] "E=j.smith@example.com, CN=John Smith, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
Private keys:
[ 3] RSA 2048 bits
```

> NOTE: You will not see the `*` characters while typing the password - they are only displayed here to indicate that the password has been typed in.

If for any reasons you will not respond *Yes* to the query about the password, the script will generate a random 12-character password and store it in a plain text file. It will display it for you to type-in and verify encrypted file.

> IMPORTANT: Do not remove nor delete certificate files from the directory. These files are needed to revoke certificate. You can delete the files after the certificate has been revoked and CRL updated, although it is a good practice to archive any issued certificate files.

## Certificate revokation and CRL management

The CA initialization script will create the first CRL file. You can repeat the process using the following command:

```shell
$ pki --signcrl --cacert $CACERT --cakey $CAKEY --digest sha256 --lifetime 31 > $CACRL
```

and display it:

```shell
$ pki --print --type crl --in $CACRL
```

A sample output:

```text
  issuer:   "CN=Example CA, E=pki@example.com, O=Example Corp., OU=IT, L=New York City, ST=New York, C=US"
  update:    this on Jul 12 11:34:48 2021, ok
             next on Aug 12 11:34:48 2021, ok (expires in 30 days)
  serial:    01
  authKeyId: a4:4e:33:63:63:58:c7:4f:0b:52:51:b5:70:8f:80:19:d9:6a:09:fc
  0 revoked certificates
```

### Revoking a certificate

The certificates have to be revoked and a new CRL has to be published once they are no longer needed or has been compromised. You can revoke a certificate using the `revoke-cert.sh` script:

```shell
$ <pki-scripts>/revoke-cert.sh <path-to-cert-file> <reason>
```

You can specify one of the following reasons:

* `cessation-of-operation`
* `superseded`
* `key-compromise`
* `ca-compromise`
* `affiliation-changed`
* `certificate-hold`

The `superseded` reason is used if the second argument is omitted.
