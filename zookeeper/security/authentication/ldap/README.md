# Demo

Pass the `client.properties` file to the CLI command  for producer/consumer.

```shell
kafka-console-producer --broker-list broker:9096 --topic test-topic --producer.config client.properties
kafka-console-consumer --bootstrap-server kafka1:9094 --topic test-topic --consumer.config client_security.properties
```

```bash
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap://localhost -a -f records.ldif

ldapsearch -H ldap://localhost -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL
```
