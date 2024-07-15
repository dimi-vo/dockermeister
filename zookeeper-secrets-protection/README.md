# Manage Secrets in CP

Secrets in CP are used to store and manage sensitive information, such as passwords and API tokens.

Secrets are administered with the `confluent secret` commands.

When running `confluent secret` the configuration file is modified to include code that directs the configuration resolution system to pull the configuration from a secret provider.
A second file, i.e. the secrets file, that contains the encrypted secrets is also created.

Secrets use "envelope encryption". The encryption algorithm is `AES/GCM/NoPadding`.

The algorithm is used to encrypt the configurations and the master encryption key.

## How secrets extend security

Secrets protection is provided for brokers, connect, and automatic resolution of variables specfied in external component configurations.

### Secrets for Dynamic Broker Configurations

Use cases for secrets protection for Apache Kafka dynamic broker configurations

1. Store all the keystore configurations encrypted in a file. The broker can use this keystore configuration instead of the dynamic broker configuration for password encryption only. This does not enable dynamic updates. Zookeeper is not used in this approach.
2. Encrypt passwords just for the broker and support dynamic updates (for example, for TLS/SSL keystores), then you can use dynamic broker configurations without new secret protection. Encrypted passwords are stored in Zookeeper.
3. Use dunamic updates for the broker if you want to use a common file for encrypted passwords of all components and the broker. A combination of the secret file and Zookeeper are used.

### Secrets and Configuration Variables

Secrets extend protection for variables in configuration files, including Connect as follows.

1. Running the `confluent secret` command encrypts secrets stored within configuration files by replacing the secret with a variable. For example with a tuple `${providerName:[path:]key}`, where `providerName` is the name of a ConfigProvider, `path` is an optional string, `key` is a required string. Running `confluent secret` adds all the information Kafka components will require to fetch the actual, decrypted value. Secrets are stored in an encrypted format in an external file.
2. With the help of Configuration Provider upon startup all components can automatically fetch the decrypted secret from the external file.
3. When using secrets to encrypt Kafka Dynamic Configurations, you must reload the configuration using the AdminClient and `kafka-configs.sh`.

## Limitations

Confluent Secrets cannot be used to encrypt the following

* A JAAS file. But you can encrypt configuration parameters referenced in a JAAS file.
* The `password.properties` file
* The `zookeeper.properties` file
* Any librdkafka-based clients
* Passwords in systemd `override.conf` files

## Demo

### Prerequisites

MDS service is configured

### Generate master encryption key based on a passphrase

Set a value for the configuration you want to encrypt.
`config.storage.topic = a-secret-name-for-a-topic`

```shell
docker compose up -d zookeeper openldap broker

confluent secret master-key generate \
--local-secrets-file ./secrets/local/secrets.properties  \
--passphrase @passphrase.txt

set CONFLUENT_SECURITY_MASTER_KEY ____PREVIOUS__OUTPUT_____

confluent secret file encrypt \
--config-file ./config/connect-standalone.properties \
--local-secrets-file ./secrets/local/secrets.properties \
--remote-secrets-file /etc/kafka/secrets/secrets.properties \
--config "config.storage.topic"

docker compose up -d connect
```

### Decrypt the encrypted configuration parameter

You can start Kafka Connect and the service will know how to decrypt the value.

Otherwise you can also do this manually

```shell
confluent secret file decrypt \
--local-secrets-file ./secrets/local/secrets.properties \
--config-file ./config/connect-standalone.properties \
--output-file decrypted-props.properties.properties
```

## Production Considerations

The orchestration tooling would have to be augmented to distribute the secrets to the destination hosts, such as brokers, connect workers, Schema Registry instances, ksqlDB servers, C3, or any service using password encryption.

You can either do the secret generation and configuration modification on each destination host directly, or do it all on a single host and the distribute the secret data to the destination hosts.

In order to distribute the secret data:

1. Export the master encryption key into the environment on every host that will have a configuration file.
2. Distribute the secrets file: Copy the secrets file `./secrets/secrets.properties` from the local host on which you have been working to `/path/to/secrets.properties` on the destination hosts
3. Propagate the necessary configuration file changes: Update the configuration file on all hosts so that the configuration parameter now has the tuple for secrets.
