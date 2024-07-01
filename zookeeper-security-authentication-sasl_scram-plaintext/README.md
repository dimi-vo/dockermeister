# Demo

SCRAM credentials are kept in the KRaft or Zookeeper, as opposed to SASL_PLAIN where they are defined in the broker's configuration file.

```shell
# Run this from inside the Zookeeper pod
kafka-configs --zookeeper localhost:2181 --alter \
  --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice-secret],SCRAM-SHA-512=[password=alice-secret]' \
  --entity-type users \
  --entity-name alice

kafka-configs --zookeeper localhost:2181 --alter \
  --add-config 'SCRAM-SHA-256=[password=admin-secret],SCRAM-SHA-512=[password=admin-secret]' \
  --entity-type users \
  --entity-name admin
```

Pass the `client.properties` file to the CLI command  for producer/consumer.

```shell
kafka-console-producer --broker-list broker:9092 --topic test-topic --producer.config client_security.properties
kafka-console-consumer --bootstrap-server broker:9092 --topic test-topic --consumer.config client_security.properties
```
