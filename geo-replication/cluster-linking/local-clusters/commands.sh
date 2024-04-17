# exec into broker-B-1 which acts as the destionation cluster
podman exec -it broker-B-1 /bin/bash
# For some reason the environment variables defined in the compose file are not picked up. Maybe they are not defined properly.
echo "confluent.cluster.link.metadata.topic.replication.factor=1" >> /etc/kafka/kraft/broker.properties
sed -i '' -e "s/confluent.cluster.link.enable=false/confluent.cluster.link.enable=true/g" /etc/kafka/kraft/broker.properties
/bin/krafka-broker-stop
# Now restart the broker
podman compose up -d

podman exec -it broker-A-1 /bin/bash

kafka-topics --create --topic demo --bootstrap-server broker-A-1:9092
kafka-console-producer --topic demo --bootstrap-server broker-A-1:9092
>one
>two
>three

kafka-console-consumer --topic demo --from-beginning --bootstrap-server broker-A-1:9092

# Create the link
kafka-cluster-links --bootstrap-server broker-B-1:9092 --create --link demo-link --config topic.config.sync.include=max.message.bytes,cleanup.policy,message.timestamp.type,message.timestamp.difference.max.ms,min.compaction.lag.ms,max.compaction.lag.ms bootstrap.servers=broker-A-1:9092
kafka-cluster-links --bootstrap-server broker-B-1:9092 --create --link demo-link --config topic.config.sync.include=max.message.bytes bootstrap.servers=broker-A-1:9092
kafka-cluster-links --bootstrap-server broker-B-1:9092 --create --link demo-link --config-file link.config
# Create the mirror topic
kafka-mirrors --create --mirror-topic dummy --link demo-link --bootstrap-server broker-B-1:9092 --config retention.ms=60000

# Describe the link
kafka-configs --bootstrap-server broker-B-1:9092 \
                  --describe \
                  --cluster-link demo-link


# Delete the mirror topic
kafka-topics --bootstrap-server broker-B-1:9092 --delete --topic dummy
# Delete the link
kafka-cluster-links --bootstrap-server broker-B-1:9092 --delete --link demo-link


# Consumer from the mirror topic
kafka-console-consumer --topic demo --from-beginning --bootstrap-server broker-B-1:9093

# See here for more details https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/topic-data-sharing.html#delete-the-link


topic.config.sync.include=max.message.bytes,message.timestamp.type,message.timestamp.difference.max.ms,min.compaction.lag.ms,max.compaction.lag.ms