# How to

## Create ACLs

```shell
kafka-acls --bootstrap-server broker:9092 \
  --command-config adminclient-configs.properties \
  --add \
  --allow-principal User:alice \
  --allow-host '*' \
  --operation read \
  --operation write \
  --operation create \
  --topic finance-topic

kafka-console-producer --bootstrap-server broker:9092 \
  --producer.config producer-configs.properties \
  --topic finance-topic

kafka-console-producer --bootstrap-server broker:9092 \
  --producer.config producer-configs-no_access.properties \
  --topic finance-topic
```
