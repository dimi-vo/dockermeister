keytool -keystore controller.keystore.jks -alias controller -keyalg RSA -validity 366 -genkey -storepass "{PASSWORD}" -keypass "{PASSWORD}" -dname "CN=controller, OU=ou, O=o, L=berlin, C=de" -ext SAN=DNS:controller
openssl req -new -x509 -keyout ca-key -out ca-cert -days 366
keytool -keystore broker.truststore.jks -alias CARoot -importcert -file ca-cert
keytool -keystore controller.truststore.jks -alias CARoot -importcert -file ca-cert
keytool -keystore controller.keystore.jks -alias controller -certreq -file cert-file
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 366 -CAcreateserial -passin pass:"{PASSWORD}"
keytool -keystore controller.keystore.jks -alias CARoot -importcert -file ca-cert
keytool -keystore controller.keystore.jks -alias controller -importcert -file cert-signed
