#!/bin/bash

#set -o nounset \
#    -o errexit \
#    -o verbose \
#    -o xtrace

# Select directory
current_dir=$(pwd)
execute_script_in_pwd=$(gum choose Yes No --header "Use the current working directory? $current_dir")

if [ "$execute_script_in_pwd" == "No" ]; then
    echo "Go to the directory you want the certificates to be created and re-run"
    exit 1
fi

# Cleanup files
files=$(ls *.{crt,csr,*_creds,jks,srl,key,pem,der,p12,log} 2>/dev/null)

# if [ -z "$files" ]; then
#   echo "No files to remove"
# else
#   echo "Removing files: "
#   echo "$files"
#   gum confirm && rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12 *.log || echo "Files not removed"
# fi


# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluentdemo.io/OU=TEST/O=CONFLUENT/L=PaloAlto/ST=Ca/C=US' -passin pass:confluent -passout pass:confluent

# ksqlDB Server (ksqldb-server) and Control Center (control-center) share a commom certificate; a separate certificate is not generated for ksqldb-server
# this shared certificate has a self-signed CA - when control-center presents the certificate to a browser visiting control-center at https://localhost:9092 ,
# it can be accepted without importing and trusting the self-signed CA, and this acceptance will also apply later to WebSockets requests to wss://localhost:8089
# (port-forwarded to ksqldb-server:8089), serving the same certificate from ksqldb-server.
#
# This is necessary as browsers never prompt to trust certificates for this kind of wss:// connection, see https://stackoverflow.com/a/23036270/452210 .
#
users2=$(gum choose broker client zookeeper ldap kafka1 kafka2 schemaregistry restproxy connect connectorSA controlCenterAndKsqlDBServer ksqlDBUser appSA badapp clientListen mds --no-limit --header "Users of Certs")
users=(client broker)
echo "Creating certificates"
printf '%s\0' "${users[@]}" | xargs -0 -I{} -n1 -P15 sh -c '$HOME/my/tools/security/create-certs/certs-create-per-user.sh "$1" > "certs-create-$1.log" 2>&1 && echo "Created certificates for $1"' -- {}
echo "Creating certificates completed"
