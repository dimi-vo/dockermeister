# Observers and AOP

## Start the cluster

We have a simple cluster consisting of 1 Zookeeper node and 3 Brokers.

```shell
docker compose up -d
```

## Define Topics with Placement Constraints

The placement contraint is defined in `config/placement.json`. It defines under which condition the Observer Promotion should take place, in this case it's when the minISR is not fulfilled.

```shell
# Create topic
docker compose exec broker-ccc \
kafka-topics --create \
--bootstrap-server broker-1:9092 \
--topic demo-topic-for-aop \
--partitions 1 \
--replica-placement /etc/kafka/demo/placement.json \
--config min.insync.replicas=2
```

## Review the topic's configuration and placement

```shell
docker compose exec broker-ccc kafka-topics --bootstrap-server broker-1:9092 --describe --topic demo-topic-for-aop
```

Output should look similar to the following.

```code
Topic: demo-topic-for-aop TopicId: Nl1LmI2tR-ONIf-1Wz4daQ PartitionCount: 1 ReplicationFactor: 3 Configs: min.insync.replicas=2,confluent.placement.constraints={"observerPromotionPolicy":"under-min-isr","version":2,"replicas":[{"count":2,"constraints":{}}],"observers":[{"count":1,"constraints":{}}]}
Topic: demo-topic-for-aop Partition: 0 Leader: 2 Replicas: 2,3,1 Isr: 2,3 Offline:  Observers: 1
```

The important part is the last part of the output.

```code
Topic: demo-topic-for-aop Partition: 0 Leader: 2 Replicas: 2,3,1 Isr: 2,3 Offline:  Observers: 1
```

What this means is that for partition 0, the only partition, the leader is broker 2. The ISR group consists of broker 2 and broker 3. There is no broker that is offline, and broker 1 is the observer. Consequently all brokers have a replica of the partition, and are therefore listed under Replicas.

## Start producing

We will use the kafka producer performance test CLI tool to continuously produce messages to the created topic.

It is important to set `acks=all` so that when a broker is brought down, the minISR condition is violated.

```shell
docker compose exec broker-ccc kafka-producer-perf-test --producer-props bootstrap.servers=broker-1:9092,broker-2:9093,broker-3:9094 acks=all --topic demo-topic-for-aop --record-size 100 --throughput 100 --num-records 3600000
```

Now leave the command running and open a new terminal.

## Bring a broker down

It is important that the broker that we will remove at this step is included in the ISR group. You should not removed the broker that is the observer, as this will have no effect.

The output of the above describe operation showed us that broker 1 is the Observer, so we will remove broker 2 in this case, but you could also remove broker 3.

```shell
# Make sure the broker is NOT the Observer, see the output of previous operation
docker compose down broker-2
```

Now for a brief moment the production of the messages will not be possible, but it will quickly recover.

```shell
# The bootstrap server should be a broker that is actively up and running
docker compose exec broker-ccc kafka-topics --bootstrap-server broker-3:9094 --describe --topic demo-topic-for-aop
```

The output now should look like the following

```code
Topic: demo-topic-for-aop TopicId: Nl1LmI2tR-ONIf-1Wz4daQ PartitionCount: 1 ReplicationFactor: 3 Configs: min.insync.replicas=2,confluent.placement.constraints={"observerPromotionPolicy":"under-min-isr","version":2,"replicas":[{"count":2,"constraints":{}}],"observers":[{"count":1,"constraints":{}}]}
Topic: demo-topic-for-aop Partition: 0 Leader: 3 Replicas: 2,3,1 Isr: 3,1 Offline: 2 Observers: 1
```

Again the important part is the last one

```code
Topic: demo-topic-for-aop Partition: 0 Leader: 3 Replicas: 2,3,1 Isr: 3,1 Offline: 2 Observers: 1
```

We can see here that the broker we stopped is now seen as Offline. Moreover, the observer is now part of the ISR, and still listed as an Observer. In the next step we will bring the removed broker back online and observe what happens with the Observer.

```shell
docker compose up -d && \
echo "Sleeping for 10 seconds so that the observer is removed from the ISR list"
sleep 10 && \
docker compose exec broker-ccc kafka-topics --bootstrap-server broker-1:9092 --describe --topic demo-topic-for-aop
```

The output should be the same as it was before bringing down the broker. The observer is removed from the ISR group and is again just an observer, now that broker-2 is back online. No broker is listed as Offline and the ISR does not include the Observer.

## Cleanup

```shell
docker compose down
```
