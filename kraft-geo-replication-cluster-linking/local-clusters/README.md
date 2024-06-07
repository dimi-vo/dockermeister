# Cluster Linking

This guide goes through an example of setting up Cluster Linking between two clusters.

The goal is to create a mirror topic and override the `retention.ms`.

The `compose.yaml` file will spin up two clusters, one broker and one controller each, as well as one Confluent Control Center instance.

## Step by step guide

```shell
# Start the containers
docker compose up -d

docker exec -it broker-A-1 /bin/bash
# Create some dummy data
kafka-topics --create --topic dummy --bootstrap-server broker-A-1:9092
kafka-console-producer --topic dummy --bootstrap-server broker-A-1:9092
>one
>two
>three

###
# Open a new terminal window or exit the broker-A-1 container
###

docker exec -it broker-B-1 /bin/bash

cd /home/user

# Create the link and pass the link.config file
kafka-cluster-links --bootstrap-server broker-B-1:9092 --create --link demo-link --config-file link.config

# Create the mirror topic and override the settings that would be synchronized
kafka-mirrors --create --mirror-topic dummy --link demo-link --bootstrap-server broker-B-1:9092 --config retention.ms=600000

# Consume the mirror topic
kafka-console-consumer --topic dummy --from-beginning --bootstrap-server broker-B-1:9092

###
# Cleanup
###

# Delete mirror topic
kafka-topics --bootstrap-server broker-B-1:9092 --delete --topic dummy
# Delete link
kafka-cluster-links --bootstrap-server broker-B-1:9092 --delete --link demo-link
```
