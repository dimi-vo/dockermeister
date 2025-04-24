# Getting Started

## Start OpenLDAP

```bash
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap://localhost -a -f records.ldif

ldapsearch -H ldap://localhost -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL
```

```shell
kafka-configs --bootstrap-server broker:29092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=kafka-secret]' --entity-type users --entity-name kafka
kafka-configs --bootstrap-server broker:29092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice-secret]' --entity-type users --entity-name alice

kafka-configs --bootstrap-server broker:9093 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=password]' --entity-type users --entity-name kafka
kafka-configs --bootstrap-server broker:9093 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice]' --entity-type users --entity-name alice
kafka-configs --bootstrap-server broker:9093 --describe --entity-type users --all

kafka-acls --bootstrap-server broker:9093 --add --cluster --operation=All --allow-principal=User:kafka








kafka-acls --authorizer-properties zookeeper.connect=localhost:2181 --add --cluster --operation=All --allow-principal=User:kafka

export KAFKA_OPTS="-Djava.security.krb5.kdc=LDAPSERVER.EXAMPLE.COM -Djava.security.krb5.realm=EXAMPLE.COM"
kafka-server-start etc/kafka/server.properties > /tmp/kafka.log 2>&1 &


```
