# Demo

Pass the `client.properties` file to the CLI command  for producer/consumer.

```shell
kafka-console-producer --broker-list kafka1:9094 --topic test-topic --producer.config client_security.properties
kafka-console-consumer --bootstrap-server kafka1:9094 --topic test-topic --consumer.config client_security.properties
```
