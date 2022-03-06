# Kafka Connect Tutorial
- [Overview](#Overview)
- [Quick Links](#Quick-Links)
- [Prequisites](#Prerequisites)
  - [Upgrading GNU Make (macOS)](#Upgrading-GNU-Make-(macOS))
- [Getting Started](#Getting-Started)
  - [Local Environment Setup](#Local-Environment-Setup)
    - [Local Environment Maintenance](#Local-Environment-Maintenance)
- [Help](#Help)
- [Kafka Infrastructure Stack](#Kafka-Infrastructure-Stack)
  - [Register the Sample Avro Schema](#Register-the-Sample-Avro-Schema)
  - [Create a Message Producer](#Create-a-Message-Producer)
  - [Consume-the-Messages-(Optional)](#Consume-the-Messages-(Optional))
  - [Sink to S3](#Sink-to-S3)
  - [Cleanup](#Cleanup)
- [Useful Commands](#Useful-Commands)
- [FAQs](#FAQs)

## Overview
[Kafka Connect](https://docs.confluent.io/current/connect/index.html#)  is a framework for scalable and reliable connections from Kafka to external systems.

At a high level, the main concepts in Kafka Connect are the [workers](https://docs.confluent.io/platform/current/connect/concepts.html#connect-workers) and  [connectors](https://docs.confluent.io/platform/current/connect/concepts.html#connect-connectors):
- Kafka Connect  **workers**  execute tasks within a pipeline
- Kafka Connect  **connectors**  define where data should be copied to and from.  Data flows into and out of Kafka are defined as source and sinks.  There are many common connectors available which can all be driven via configuration.

Kafka Connect provides:
- Performance via scalable and parallelisable tasks (to  _N_  Kafka partitions)
- Fault tolerance by managing worker state redistribution on failures
- Highly available distributed service (or standalone for small implementations)
- Low latency (2 x AWS ECS m5.large can process ~15M records in approximately one minute)

The following demonstration uses the [Confluent REST-API](https://docs.confluent.io/platform/current/kafka-rest/api.html) to interact with a Kakfa cluster to produce and consume an Avro message.
## Quick Links
- [Kafka Connect](https://docs.confluent.io/current/connect/index.html#)
- [Kafka Schema Registry API](https://docs.confluent.io/platform/current/schema-registry/develop/api.html)
- [Confluent REST API](https://docs.confluent.io/platform/current/kafka-rest/api.html)

## Prerequisites
- [GNU make](https://www.gnu.org/software/make/manual/make.html>)
- [Docker](https://www.docker.com/)

### Upgrading GNU Make (macOS)
Although the macOS machines provide a working GNU `make` it is too old to support the capabilities within the DevOps utilities package, [makester](https://github.com/loum/makester).  Instead, it is recommended to upgrade to the GNU make version provided by Homebrew.  Detailed instructions can be found at https://formulae.brew.sh/formula/make .  In short, to upgrade GNU make run:
```
brew install make
```
The `make` utility installed by Homebrew can be accessed by `gmake`.  The https://formulae.brew.sh/formula/make notes suggest how you can update your local `PATH` to use `gmake` as `make`.  Alternatively, alias `make`:
```
alias make=gmake
```
## Getting Started
### Local Environment Setup
Get the code and change into the top level `git` project directory:
```
git clone https://github.com/loum/data-kafka-connect && cd data-kafka-connect
```
For first-time setup, get the [Makester project](https://github.com/loum/makester.git):
```
git submodule update --init
```
Initialise the environment:
```
make init
```
#### Local Environment Maintenance
Keep [Makester project](https://github.com/loum/makester.git) up-to-date with:
```
git submodule update --remote --merge
```
## Help
There should be a `make` target to be able to get most things done.  Check the help for more information:
```
make help
```
## Kafka Infrastructure Stack
Build the Kafka cluster with a Kafka Connect worker in distributed mode:
```
make stack-up
```
### Register the Sample Avro Schema
```
curl -X POST\
 -H "Content-Type: application/vnd.schemaregistry.v1+json"\
 --data @docker/files/schemas/develop/sample-sink-avro-schema.json\
 http://localhost:8081/subjects/sample-sink-value/versions
```
The Kafka Schema Registry response value denotes the ID of the schema:
```
{"id":1}
```
This registers a schema under a *subject* named  `sample-sink-value`.  The convention used by the serializers to register schemas under a name that follows the  `<topic>-(key|value)`  format.

Schema versions can be checked any time with the command:
```
curl http://localhost:8081/subjects/sample-sink-value/versions/
```
```
# Schema version of the subject "sample-sink-value"
[1]
```
Detailed output can be achieved by specifying the schema version number:
```
curl http://localhost:8081/subjects/sample-sink-value/versions/1 | jq
```
```
{
  "subject": "sample-sink-value",
  "version": 1,
  "id": 1,
  "schema": "{\"type\":\"record\",\"name\":\"KafkaEvent\",\"namespace\":\"com.lfs.cm.interpreters\", ...}"
}
```
### Create a Message Producer
Manually add messages to the Kafka topic in preparation for the sink to the object store.  Use the Confluent REST Proxy API to produce records:
```
curl -X POST\
 -H "Content-Type: application/vnd.kafka.avro.v2+json"\
 -H "Accept: application/vnd.kafka.v2+json"\
 --data '{"value_schema_id": 1, "records": [{"value": {"data": {"Id": "98cf1dc6-6f2b-4d9d-b733-f45e7d71aded"}}}]}'\
 http://localhost:8082/topics/sample-sink
```
On success, you should output similar to the following:
```
{"offsets":[{"partition":0,"offset":0,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":1}
```
### Consume the Messages (Optional)
Kafka REST Proxy API a facility to consume messages from a Kafka topic.  First, create the consumer.  This particular example will create a consumer for Avro data starting at the beginning of the topic's log:
```
curl -X POST\
 -H "Content-Type: application/vnd.kafka.v2+json"\
 --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}'\
 http://localhost:8082/consumers/my_avro_consumer
```
Next, subscribe to the `sample-sink` topic:
```
curl -X POST\
 -H "Content-Type: application/vnd.kafka.v2+json"\
 --data '{"topics":["sample-sink"]}'\
 http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/subscription
```
Consume messages from the topic.  This is decoded, translated to JSON and included in the response.  The schema used for deserialization is fetched automatically from schema registry:
```
curl -X GET\
 -H "Accept: application/vnd.kafka.avro.v2+json"\
 http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/records
```
Finally, clean up:
```
curl -X DELETE\
 -H "Content-Type: application/vnd.kafka.v2+json"\
 http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance
```
### Sink to S3
For demonstration purposes (and to avoid AWS interfaces during PoC), we will be using MINIO as the sink.  Navigate to [http://localhost:9001](http://localhost:9001/) and login to the Minio console with the hardwired test credentials.
> **_NOTE:_** The following are TEST credentials only that were auto-generated by the MINIO docker container on initial start up and re-used here for simplicity.  **Do not use these credentials in a pro/sample-snduction environment.**

- **Username:**  `00000000000000000000`
- **Password:**  `abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN`

Once logged in you should see the  `sample-sink-bucket`  bucket.

Kafka Connect uses connectors to move data in and out of infrastructure components.  Source and sink are conventions used within Kafka Connect to identify data moving into Kafka (source) and data moving out of Kafka (sink).

Kafka Connect exposes a REST API on port  `28083`  that can be used to interact with the service.

Enter the following command to create a Kafka Connect sink to the object store:
```
curl --silent -X POST\
 -H "Content-Type: application/json"\
 --data @docker/files/connectors/properties/sample-sink-connector.s3.properties.json\
 http://localhost:28083/connectors | jq .
```
```
# Typical response when the object store sink has been created successfully:
{
  "name": "sample-sink",
  "config": {
    "name": "sample-sink",
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "tasks.max": "1",
    "topics": "sample-sink",
    "topics.dir": "sample-sink",
    "s3.part.size": "5242880",
    "flush.size": "1",
    "s3.bucket.name": "sample-sink",
    "store.url": "http://minio:9000",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "schema.generator.class": "io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator",
    "partitioner.class": "io.confluent.connect.storage.partitioner.DailyPartitioner",
    "locale": "en-AU",
    "timezone": "UTC",
    "timestamp.extractor": "Record",
    "rotate.schedule.interval.ms": "60000",
    "schema.compatibility": "NONE"
  },
  "tasks": [],
  "type": "sink"
}
```
This will also start the sink to S3.  Check the MINIO dashboard to see the messages present in JSON format.

To query the list of available connectors:
```
curl http://localhost:28083/connectors
```
```
# Active Kafka connectors:
[sample-sink]
```
### Cleanup
Remove the containers and data:
```
make stack-down
```
## Useful Commands
### `make bootstrap`
Helper target that performs all the steps in the tutorial in one action.  Handy if you just want to start working with Kafka Connect.
## FAQs
**_Q. Why is the default make on macOS so old?_**
Apple seems to have an issue with licensing around GNU products: more specifically to the terms of the GPLv3 license agreement.  It is unlikely that Apple will provide current versions of utilities that are bound by the GPLv3 licensing constraints.

---
[top](#Kafka-Connect-Tutorial)
