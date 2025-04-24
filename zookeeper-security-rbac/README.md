# Getting Started

## Generate the Certificates for the MDS to LDAP connection

```shell
cd ./security/ldap/certs

# Create the Certificate Authority
openssl req -new -x509 -keyout ca.key -days 365 -nodes -subj "/CN=root-ca" -out ca.crt

# Create the LDAP's server key and certificate
openssl req -new -nodes -out server.csr -keyout server.key -subj "/CN=openldap"
openssl x509 -req -in server.csr -days 365 -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# Create a TrustStore and import the CA certificate into it
keytool -import -v -alias testroot -file ca.crt -keystore ldap_truststore.jks -storetype JKS -storepass 'welcome123' -noprompt

# Display the TrustStore
keytool -list -keystore ldap_truststore.jks -storepass 'welcome123' -v


cd ../../conf
# Create the private key for token signing
openssl genrsa -out keypair.pem 2048
# Create the public key for token signing
openssl rsa -in server.key -outform PEM -pubout -out public.pem
cd ../..
```

## Generate the certificates for the TLS communication

```shell
certs-create.sh
```

## Start the services and create the bindings

```shell
docker compose up zookeeper broker openldap -d

# Create role bindings for principals
set MDS_URL http://localhost:8091
set SUPER_USER superUser
set SUPER_USER_PASSWORD superUser
set SUPER_USER_PRINCIPAL "User:$SUPER_USER"
set C3_ADMIN "User:controlcenterAdmin"
set CLIENT_AVRO_PRINCIPAL "User:clientAvroCli"

# username: superUser
# password: superUser
confluent login --url $MDS_URL -vvvv

set KAFKA_CLUSTER_ID (confluent cluster describe --url $MDS_URL | grep "Confluent Resource Name" | awk -F': ' '{print $2}') && echo $KAFKA_CLUSTER_ID

echo "Creating role bindings for Super User"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal $SUPER_USER_PRINCIPAL

echo "Creating role bindings for C3 Admin"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal $C3_ADMIN

echo "Create role bindings for Alice"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal User:alice
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role DeveloperRead --principal User:alice --resource Topic:demo
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role DeveloperRead --principal User:alice --resource Group:console-consumer- --prefix 

echo "Create role bindings for client"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal User:client

# Delete a Role Binding
confluent iam rbac role-binding delete --role SystemAdmin --principal User:alice --kafka-cluster $KAFKA_CLUSTER_ID

docker compose up control-center -d
```

## Connect Client

```shell
# Consume
kafka-console-consumer --bootstrap-server https://localhost:9093 --topic demo --from-beginning --consumer.config ../../demo-configs/client-tls.properties

# Produce
kafka-console-producer --broker-list https://localhost:9093 --topic demo --producer.config ../../demo-configs/client-tls.properties
```

## Work In Progress - Ignore

```shell
# ResourceOwner for groups and topics on broker
for resource in Topic:_schemas Group:schema-registry
do
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

for role in DeveloperRead DeveloperWrite
do
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role $role \
        --resource $LICENSE_RESOURCE \
        --kafka-cluster-id $KAFKA_CLUSTER_ID

    # starting from 6.2.3 and 7.0.2, it is replaced by _confluent-command
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role $role \
        --resource Topic:_confluent-command \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done


################################### Client Avro CLI ###################################
echo "Creating role bindings for the Avro CLI"

confluent iam rolebinding create \
    --principal $CLIENT_AVRO_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:clientAvro \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $CLIENT_AVRO_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $CLIENT_AVRO_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:_confluent-monitoring \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $CLIENT_AVRO_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

######################### Print #########################

echo "Cluster IDs:"
echo "    kafka cluster id: $KAFKA_CLUSTER_ID"
echo "    connect cluster id: $CONNECT"
echo "    schema registry cluster id: $SR"
echo "    ksql cluster id: $KSQLDB"
echo
echo "Cluster IDs as environment variables:"
echo "    export KAFKA_ID=$KAFKA_CLUSTER_ID ; export CONNECT_ID=$CONNECT ; export SR_ID=$SR ; export KSQLDB_ID=$KSQLDB"
echo
echo "Principals:"
echo "    super user account: $SUPER_USER_PRINCIPAL"
echo "    Schema Registry user: $SR_PRINCIPAL"
echo "    Connect Admin: $CONNECT_ADMIN"
echo "    Connector Submitter: $CONNECTOR_SUBMITTER"
echo "    Connector Principal: $CONNECTOR_PRINCIPAL"
echo "    ksqlDB Admin: $KSQLDB_ADMIN"
echo "    ksqlDB User: $KSQLDB_USER"
echo "    ksqlDB Server: $KSQLDB_SERVER"
echo "    C3 Admin: $C3_ADMIN"
echo "    Client Avro CLI Principal: $CLIENT_AVRO_PRINCIPAL"
echo
```
