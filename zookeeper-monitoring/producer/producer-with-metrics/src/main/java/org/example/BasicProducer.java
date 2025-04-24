package org.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

public class BasicProducer {

    public static void main(String[] args) {
        var producer = createProducer();

        String topic = "demo";

        for (int i = 0; i < 10; i++) {
            final ProducerRecord<String, String> record = new ProducerRecord<>(topic, String.valueOf(i), "Record #" + i + ".");
            int finalI = i;
            producer.send(record, (recordMetadata, e) -> System.out.println("Completed for record " + finalI));
        }


        System.out.println("Hello world!");
    }

    private static KafkaProducer<String, String> createProducer() {
        Properties config = new Properties();
        config.put("client.id", "1");
        config.put("bootstrap.servers", "localhost:9092");
        config.put("acks", "all");
        return new KafkaProducer<>(config);
    }
}
