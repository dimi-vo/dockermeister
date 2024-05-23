# ZooKeeper and Broker Keystore
keytool -keystore zookeeper.keystore.jks -alias zookeeper -keyalg RSA -validity 366 -genkey -storepass qaqaqa -keypass qaqaqa -dname "CN=zookeeper, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:zookeeper &&
keytool -keystore broker.keystore.jks -alias broker -keyalg RSA -validity 366 -genkey -storepass qaqaqa -keypass qaqaqa -dname "CN=broker, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:broker

## Create CA
openssl req -new -x509 -keyout ca-key -out ca-cert -days 366

## Create broker's truststore and import the CA certificate
keytool -keystore broker.truststore.jks -alias CARoot -importcert -file ca-cert
## Create zookeepers's truststore and import the CA certificate
keytool -keystore zookeeper.truststore.jks -alias CARoot -importcert -file ca-cert

## Export the zookeeper's certificate. First step for signing it (server)
keytool -keystore zookeeper.keystore.jks -alias zookeeper -certreq -file zookeeper-cert-file
## Sign zookeeper's certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in zookeeper-cert-file -out zookeeper-cert-signed -days 366 -CAcreateserial -passin pass:qaqaqa
## Import the CA Root certificate into the zookeeper (server)
keytool -keystore zookeeper.keystore.jks -alias CARoot -importcert -file ca-cert
## Import the zookeeper certificate into the zookeeper (server)
keytool -keystore zookeeper.keystore.jks -alias zookeeper -importcert -file zookeeper-cert-signed


## Import the CA certificate into the broker's truststore (client)
######see above
## Export the broker's certificate. First step for signing it (server)
keytool -keystore broker.keystore.jks -alias broker -certreq -file broker-cert-file
## Sign the certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in broker-cert-file -out broker-cert-signed -days 366 -CAcreateserial -passin pass:qaqaqa
## Import the controller certificate into the ccc (server)
keytool -keystore broker.keystore.jks -alias CARoot -importcert -file ca-cert
keytool -keystore broker.keystore.jks -alias broker -importcert -file broker-cert-signed

# CCC <> client
keytool -keystore ccc.keystore.jks -alias ccc -keyalg RSA -validity 366 -genkey -storepass absurd -keypass absurd -dname "CN=ccc, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:localhost
## Export the ccc's certificate. First step for signing it (server)
keytool -keystore ccc.keystore.jks -alias ccc -certreq -file ccc-cert-file
## Sign the certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in ccc-cert-file -out ccc-cert-signed -days 366 -CAcreateserial -passin pass:absurd
## Import the controller certificate into the ccc (server)
keytool -keystore ccc.keystore.jks -alias CARoot -importcert -file ca-cert
keytool -keystore ccc.keystore.jks -alias ccc -importcert -file ccc-cert-signed
