# Getting Started

## Start OpenLDAP

```bash
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap://localhost -a -f records.ldif

ldapsearch -H ldap://localhost -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL
```

```shell
kafka-configs --bootstrap-server broker:29092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=kafka-secret]' --entity-type users --entity-name kafka
kafka-configs --bootstrap-server broker:29092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice-secret]' --entity-type users --entity-name alice

kafka-configs --bootstrap-server broker:9093 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=password]' --entity-type users --entity-name kafka
kafka-configs --bootstrap-server broker:9093 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice]' --entity-type users --entity-name alice
kafka-configs --bootstrap-server broker:9093 --describe --entity-type users --all

kafka-acls --bootstrap-server broker:9093 --add --cluster --operation=All --allow-principal=User:kafka








kafka-acls --authorizer-properties zookeeper.connect=localhost:2181 --add --cluster --operation=All --allow-principal=User:kafka

export KAFKA_OPTS="-Djava.security.krb5.kdc=LDAPSERVER.EXAMPLE.COM -Djava.security.krb5.realm=EXAMPLE.COM"
kafka-server-start etc/kafka/server.properties > /tmp/kafka.log 2>&1 &

###############################################################################################
###############################################################################################
###############################################################################################

mkdir ./ldap/ldap_certs

cd ldap/ldap_certs

echo "LDAPS: Creating a Root Certificate Authority (CA)"
openssl req -new -x509 -days 365 -nodes -out ca.crt -keyout ca.key -subj "/CN=root-ca"

echo "LDAPS: Generate the LDAPS server key and certificate"
openssl req -new -nodes -out server.csr -keyout server.key -subj "/CN=openldap"
openssl x509 -req -in server.csr -days 365 -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

echo "LDAPS: Create a JKS truststore"
rm -f ldap_truststore.jks
# We import the test CA certificate
keytool -import -v -alias testroot -file ca.crt -keystore ldap_truststore.jks -storetype JKS -storepass 'welcome123' -noprompt

echo "LDAPS: Displaying truststore"
keytool -list -keystore ldap_truststore.jks -storepass 'welcome123' -v
cd -

# Generating public and private keys for token signing
echo "Generating public and private keys for token signing"
mkdir conf
cd conf
openssl genrsa -out keypair.pem 2048
openssl rsa -in keypair.pem -outform PEM -pubout -out public.pem 

cd ..
chown -R $(id -u $USER):$(id -g $USER) conf/
chmod 644 conf/keypair.pem

echo "Available LDAP users:"
docker exec openldap ldapsearch -x -h localhost -b dc=confluentdemo,dc=io -D "cn=admin,dc=confluentdemo,dc=io" -w admin | grep uid:


#####################################################

cd security/ldap/certs

# Create the Certificate Authority
openssl req -new -x509 -keyout ca.key -days 365 -nodes -subj "/CN=root-ca" -out ca.crt

# Create the LDAP's server key and certificate
openssl req -new -nodes -out server.csr -keyout server.key -subj "/CN=openldap"
openssl x509 -req -in server.csr -days 365 -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# Create a TrustStore and import the CA certificate into it
keytool -import -v -alias testroot -file ca.crt -keystore ldap_truststore.jks -storetype JKS -storepass 'welcome123' -noprompt

# Display the TrustStore
keytool -list -keystore ldap_truststore.jks -storepass 'welcome123' -v

# Create public and private keys for token signing
openssl genrsa -out keypair.pem 2048
openssl rsa -in keypair.pem -outform PEM -pubout -out public.pem

#####################################################
#####################################################
#####################################################



echo "Creating role bindings for principals"

################################## SETUP VARIABLES #############################
MDS_URL=http://localhost:8091
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_ADMIN="User:connectAdmin"
CONNECTOR_SUBMITTER="User:connectorSubmitter"
CONNECTOR_PRINCIPAL="User:connectorSA"
SR_PRINCIPAL="User:schemaregistryUser"
C3_ADMIN="User:controlcenterAdmin"
KSQLDB_ADMIN="User:ksqlDBAdmin"
KSQLDB_USER="User:ksqlDBUser"
KSQLDB_SERVER="User:controlCenterAndKsqlDBServer"
CLIENT_AVRO_PRINCIPAL="User:clientAvroCli"
LICENSE_RESOURCE="Topic:_confluent-license" # starting from 6.2.3 and 7.0.2, it is replaced by _confluent-command

mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD} || exit 1

################################### SUPERUSER ###################################
echo "Creating role bindings for Super User"

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL  \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQLDB

################################### SCHEMA REGISTRY ###################################
echo "Creating role bindings for Schema Registry"

# SecurityAdmin on SR cluster itself
confluent iam rolebinding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

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

################################### CONNECT Admin ###################################
echo "Creating role bindings for Connect Admin"

# SecurityAdmin on the connect cluster itself
confluent iam rolebinding create \
    --principal $CONNECT_ADMIN \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

# ResourceOwner for groups and topics on broker
declare -a ConnectResources=(
    "Topic:connect-configs"
    "Topic:connect-offsets"
    "Topic:connect-status"
    "Group:connect-cluster"
    "Topic:_confluent-monitoring"
    "Topic:_confluent-command"
    "Topic:_confluent-secrets"
    "Group:secret-registry"
)
for resource in ${ConnectResources[@]}
do
    confluent iam rolebinding create \
        --principal $CONNECT_ADMIN \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### Connectors ###################################
echo "Creating role bindings for any connector"

confluent iam rolebinding create \
    --principal $C3_ADMIN \
    --role ResourceOwner \
    --resource Connector:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $CONNECTOR_SUBMITTER \
    --role ResourceOwner \
    --resource Connector:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $CONNECTOR_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \

confluent iam rolebinding create \
    --principal $CONNECTOR_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $CONNECTOR_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:* \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

################################### ksqlDB Admin ###################################
echo "Creating role bindings for ksqlDB Admin"

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource KsqlCluster:$KSQLDB \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQLDB

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role DeveloperRead \
    --resource Group:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Topic:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Subject:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Topic:_confluent-monitoring \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Topic:${KSQLDB}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role DeveloperRead \
    --resource Topic:wikipedia.parsed \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Topic:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource TransactionalId:${KSQLDB} \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Subject:wikipedia \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Subject:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role ResourceOwner \
    --resource Subject:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

# enable.idempotence=true requires IdempotentWrite
confluent iam rolebinding create \
    --principal $KSQLDB_ADMIN \
    --role DeveloperWrite \
    --resource Cluster:kafka-cluster \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

################################### ksqlDB User ###################################
echo "Creating role bindings for ksqlDB User"

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role DeveloperWrite \
    --resource KsqlCluster:$KSQLDB \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQLDB

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role DeveloperRead \
    --resource Group:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role ResourceOwner \
    --resource Topic:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role ResourceOwner \
    --resource Subject:_confluent-ksql-${KSQLDB} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role DeveloperRead \
    --resource Topic:${KSQLDB}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role DeveloperRead \
    --resource Topic:wikipedia.parsed \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role ResourceOwner \
    --resource Subject:wikipedia \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role ResourceOwner \
    --resource Topic:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role ResourceOwner \
    --resource Subject:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

# enable.idempotence=true requires IdempotentWrite
confluent iam rolebinding create \
    --principal $KSQLDB_USER \
    --role DeveloperWrite \
    --resource Cluster:kafka-cluster \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

################################### KSQLDB Server #############################
echo "Creating role bindings for ksqlDB Server (used for ksqlDB Processing Log)"
confluent iam rolebinding create \
    --principal $KSQLDB_SERVER \
    --role ResourceOwner \
    --resource Topic:${KSQLDB}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

############################## Control Center ###############################
echo "Creating role bindings for Control Center"

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rolebinding create \
    --principal $C3_ADMIN \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID


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















log "Validate bindings"
docker exec -i tools bash -c "/tmp/helper/validate_bindings.sh"

docker compose -f ../../environment/plaintext/docker-compose.yml -f ../../environment/rbac-sasl-plain/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} build
docker compose -f ../../environment/plaintext/docker-compose.yml -f ../../environment/rbac-sasl-plain/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_kafka_nodes_command} ${profile_connect_nodes_command} up -d --quiet-pull
log "📝 To see the actual properties file, use cli command playground container get-properties -c <container>"
command="source ${DIR}/../../scripts/utils.sh && docker compose -f ${DIR}/../../environment/plaintext/docker-compose.yml -f ${DIR}/../../environment/rbac-sasl-plain/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_kafka_nodes_command} ${profile_connect_nodes_command} up -d --quiet-pull"
playground state set run.docker_command "$command"
playground state set run.environment "rbac-sasl-plain"
log "✨ If you modify a docker-compose file and want to re-create the container(s), run cli command playground container recreate"


wait_container_ready

display_jmx_info



```
