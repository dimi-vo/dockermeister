# Manage resources in CP with CFK

## Prerequisites

- Docker
- `minikube` - [install](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download)
- `kubectl` - [install](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `helm` - [install](https://helm.sh/docs/intro/install/)
- An http client or CLI tool. In this example [curl](https://github.com/curl/curl) is used.

Helpful but not required
- `k9s` - [install](https://k9scli.io/topics/install/)



## Getting Started


Start the cluster in docker. We don't deploy anything to k8s yet.

```shell
docker compose up -d
```

Create the k8s cluster that will be used for CfK. Practically, just the operator is going to live there.

```shell

docker network create -d bridge test-net --subnet=172.25.0.0/24 --gateway=172.25.0.1



# set home directory
export TUTORIAL_HOME="https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart"

# create the namespace to use
kubectl create namespace confluent
# Set the created namespace for the k8s context
kubectl config set-context --current --namespace confluent
# Add the CfK Heml repository
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
# Install CfK
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes
# Check that the CfK pod comes up and is running
kubectl get pods



kubectl apply -f admin-rest-class-cr.yaml

kubectl apply -f kafka-topic.yaml
```




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
openssl rsa -in keypair.pem -outform PEM -pubout -out public.pem
cd ../..
```

## Generate the certificates for the TLS communication

```shell
certs-create.sh
```

Now move them to security/ldap/certs

## Start the services and create the bindings

```shell
docker compose up zookeeper broker openldap -d

# Create role bindings for principals
set MDS_URL https://localhost:8091
set SUPER_USER superUser
set SUPER_USER_PASSWORD superUser
set SUPER_USER_PRINCIPAL "User:$SUPER_USER"
set C3_ADMIN "User:controlcenterAdmin"
set CLIENT_AVRO_PRINCIPAL "User:clientAvroCli"

# username: superUser
# password: superUser
confluent login --url $MDS_URL -vvvv --ca-cert-path ./security/ssl/snakeoil-ca-1.crt

set KAFKA_CLUSTER_ID (confluent cluster describe --url $MDS_URL --ca-cert-path ./security/ssl/snakeoil-ca-1.crt | grep "Confluent Resource Name" | awk -F': ' '{print $2}') && echo $KAFKA_CLUSTER_ID

echo "Creating role bindings for Super User"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal $SUPER_USER_PRINCIPAL

echo "Creating role bindings for C3 Admin"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal $C3_ADMIN

echo "Create role bindings for client"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal User:client

echo "Create role bindings for Alice"
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role SystemAdmin --principal User:alice
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role DeveloperRead --principal User:alice --resource Topic:demo
confluent iam rbac role-binding create --kafka-cluster $KAFKA_CLUSTER_ID --role DeveloperRead --principal User:alice --resource Group:console-consumer- --prefix 


#Go to http://localhost:8092/security/openapi/swagger-ui/index.html for the swagger UI

# Review this https://support.confluent.io/hc/en-us/articles/15190226267796-How-to-bypass-basic-txt-in-secretRef-connect-basic-username-and-password-not-formatted-correctly-error-in-Confluent-for-Kubernetes
kubectl create secret generic credential \
           --from-file=basic.txt=super-secret.txt \
           --namespace confluent

# For the REST Admin API check this -> https://github.com/confluentinc/cp-demo/blob/7.7.0-post/docker-compose.yml


curl --user superUser:superUser http://localhost:8092/kafka/v3/clusters/ -v

# Delete a Role Binding
confluent iam rbac role-binding delete --role SystemAdmin --principal User:alice --kafka-cluster $KAFKA_CLUSTER_ID

docker compose up control-center -d
```

## Connect Client

```shell
# The clients use the certificates issued for the User:client. Make sure to create RBAC roles for it, before using
# Consume
kafka-console-consumer --bootstrap-server https://localhost:9093 --topic demo --from-beginning --consumer.config ./client-configs/client-tls.properties

# Produce
kafka-console-producer --broker-list https://localhost:9093 --topic demo --producer.config ./client-configs/client-tls.properties
```

## Get the AuthToken

Consider using http or https

```shell

set TOKEN (http --verify ./security/ssl/snakeoil-ca-1.crt http://localhost:8092/security/1.0/authenticate -a superUser:superUser | jq '.auth_token' -r) && echo $TOKEN



http --verify snakeoil-ca-1.crt http://localhost:8092/security/1.0/authenticate -a superUser:superUser
HTTP/1.1 200 OK
Content-Encoding: gzip
Content-Length: 526
Content-Type: application/json
Date: Thu, 19 Sep 2024 16:22:07 GMT
Set-Cookie: auth_token=eyJhbGciOiJSUzI1NiIsImtpZCI6bnVsbH0.eyJqdGkiOiJBQ1lzUkZJbk1ZMEQ4N1RoQmVOYTdnIiwiaXNzIjoiQ29uZmx1ZW50Iiwic3ViIjoic3VwZXJVc2VyIiwiZXhwIjoxNzI2NzY2NTI3LCJpYXQiOjE3MjY3NjI5MjcsIm5iZiI6MTcyNjc2Mjg2NywiYXpwIjoic3VwZXJVc2VyIiwiYXV0aF90aW1lIjoxNzI2NzYyOTI3fQ.E60dpaGw-7YWbx0o5S86TpCnYvrd_dsKfF6rV0BwgE-ILCJM9_ikkRVXNSv6NDmJimpMAL3twZeJ494kA2-fatRxbYMjUHZjA3-9IsdZaiPoOnrDN91_ktQNL5vj0UzO70tf-b-lG2TomTZgqHJUuMDqB8HfIdtsR1LXZBevXxDSSsjUuAc78dXRIuOAFcGxGdvTAyk3AtbL-hwWACnxxSLrBTRtYEHs3eBJ6kCpfU4a0a3ZGuDW8RjDZ4kNlrXGQnW5ZVYGT6yXs6bsVNVbU1s7uJhIZzFgIDVu6tX1n8LrU30VanxFOTimeQS49x7HwimoU2rDPpWsVOTsDK44hQ; HttpOnly; Secure; Path=/; Expires=Thu, 19-Sep-2024 17:22:07 GMT; SameSite=Lax; Max-Age=3600
Vary: Accept-Encoding, User-Agent

{
    "auth_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6bnVsbH0.eyJqdGkiOiJBQ1lzUkZJbk1ZMEQ4N1RoQmVOYTdnIiwiaXNzIjoiQ29uZmx1ZW50Iiwic3ViIjoic3VwZXJVc2VyIiwiZXhwIjoxNzI2NzY2NTI3LCJpYXQiOjE3MjY3NjI5MjcsIm5iZiI6MTcyNjc2Mjg2NywiYXpwIjoic3VwZXJVc2VyIiwiYXV0aF90aW1lIjoxNzI2NzYyOTI3fQ.E60dpaGw-7YWbx0o5S86TpCnYvrd_dsKfF6rV0BwgE-ILCJM9_ikkRVXNSv6NDmJimpMAL3twZeJ494kA2-fatRxbYMjUHZjA3-9IsdZaiPoOnrDN91_ktQNL5vj0UzO70tf-b-lG2TomTZgqHJUuMDqB8HfIdtsR1LXZBevXxDSSsjUuAc78dXRIuOAFcGxGdvTAyk3AtbL-hwWACnxxSLrBTRtYEHs3eBJ6kCpfU4a0a3ZGuDW8RjDZ4kNlrXGQnW5ZVYGT6yXs6bsVNVbU1s7uJhIZzFgIDVu6tX1n8LrU30VanxFOTimeQS49x7HwimoU2rDPpWsVOTsDK44hQ",
    "expires_in": 3600,
    "token_type": "Bearer"
}



http --verify snakeoil-ca-1.crt http://localhost:8091/v1/metadata/id
HTTP/1.1 200 OK
Content-Encoding: gzip
Content-Length: 94
Content-Type: application/json
Date: Thu, 19 Sep 2024 16:24:35 GMT
Vary: Accept-Encoding, User-Agent

{
    "id": "1uuYR_zTRwi3hpiL06z80g",
    "scope": {
        "clusters": {
            "kafka-cluster": "1uuYR_zTRwi3hpiL06z80g"
        },
        "path": []
    }
}


http --verify snakeoil-ca-1.crt http://localhost:8092/kafka/v3/clusters "Authorization:Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6bnVsbH0.eyJqdGkiOiJSNTloY1NoU2p3RzhMeVplS3JuQ3pRIiwiaXNzIjoiQ29uZmx1ZW50Iiwic3ViIjoic3VwZXJVc2VyIiwiZXhwIjoxNzI2NzY4MDI2LCJpYXQiOjE3MjY3NjQ0MjYsIm5iZiI6MTcyNjc2NDM2NiwiYXpwIjoic3VwZXJVc2VyIiwiYXV0aF90aW1lIjoxNzI2NzY0NDI2fQ.dMol5WjAHlfiUPBdDjlXnrGcbyKyCS-6OcCRb6PGCqzMZR-2pM68v8LOV5NB3X2Iscpeqpzzux8S_YZ9oQn-xz49SoZgVQ_l0UpImkIXMc_Umq-QHqbrQ_YxkvocBHLJd7bTfdN0GAg6edzz6SXP10pdSlc1_tY6NyRmT1JJXUbX0m5061G6iLoYU7EW4wJioPMr-LESY8l9Je4x082jzWXvnXZqLV1UxuuzjkWa6q3a7XrK6kBVnP5TGwrxU3IN79UigQqr-vWsataCW3zGSaT4GAhl0N-ir9k5kSYuadbtpPL_I5lyuOYaRw_V-z2M_5j9KdKKKYdNcAxvSJP_rQ"
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



