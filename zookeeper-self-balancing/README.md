# How To, What To

```shell


# Create the demo topic
kafka-topics --bootstrap-server broker-1:9092 --create --topic test --replication-factor 2 --partitions 3

# Start the message production
kafka-producer-perf-test --producer-props bootstrap.servers=broker-1:9092,broker-2:9092,broker-3:9092 --topic test --record-size 100 --throughput 100 --num-records 3600000

watch kafkacat -b broker-1:9092 -L -t test
```
