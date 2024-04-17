# Getting Started

## Start OpenLDAP

```bash
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap://localhost -a -f records.ldif

ldapsearch -H ldap://localhost -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL
```

```shell
kafka-configs --bootstrap-server localhost:9092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=kafka-secret]' --entity-type users --entity-name kafka
kafka-configs --bootstrap-server localhost:9092 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=alice-secret]' --entity-type users --entity-name alice
```
