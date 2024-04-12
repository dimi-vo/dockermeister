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
kafka-cluster-links --bootstrap-server broker-dest:9093 --create --link demo-link --config bootstrap.servers=broker-source:9092

# Create the mirror topic
kafka-mirrors --create --mirror-topic demo --link demo-link --bootstrap-server broker-dest:9093

# Consumer from the mirror topic
kafka-console-consumer --topic demo --from-beginning --bootstrap-server broker-B-1:9093

# See here for more details https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/topic-data-sharing.html#delete-the-link
