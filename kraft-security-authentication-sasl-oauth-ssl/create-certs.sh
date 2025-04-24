# SSL Controller <> Broker
keytool -keystore controller.keystore.jks -alias controller -keyalg RSA -validity 366 -genkey -storepass "{PASSWORD}" -keypass "{PASSWORD}" -dname "CN=controller, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:controller
## Create CA
openssl req -new -x509 -keyout ca-key -out ca-cert -days 366
## Import the CA certificate into the broker's truststore (client)
keytool -keystore broker.truststore.jks -alias CARoot -importcert -file ca-cert
## Import the CA certificate into the controller's truststore (server)
keytool -keystore controller.truststore.jks -alias CARoot -importcert -file ca-cert
## Export the controller's certificate. First step for signing it (server)
keytool -keystore controller.keystore.jks -alias controller -certreq -file cert-file
## Sign the certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 366 -CAcreateserial -passin pass:"{PASSWORD}"
## Import the CA Root certificate into the controller (server)
keytool -keystore controller.keystore.jks -alias CARoot -importcert -file ca-cert
## Import the controller certificate into the controller (server)
keytool -keystore controller.keystore.jks -alias controller -importcert -file cert-signed

# SSL Broker <> CCC
keytool -keystore broker.keystore.jks -alias broker -keyalg RSA -validity 366 -genkey -storepass absurd -keypass absurd -dname "CN=broker, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:broker
## Import the CA certificate into the broker's truststore (client)
keytool -keystore client.truststore.jks -alias CARoot -importcert -file ca-cert
## Export the broker's certificate. First step for signing it (server)
keytool -keystore broker.keystore.jks -alias broker -certreq -file broker-cert-file
## Sign the certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in broker-cert-file -out broker-cert-signed -days 366 -CAcreateserial -passin pass:absurd
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
