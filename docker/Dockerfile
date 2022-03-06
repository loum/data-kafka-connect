FROM confluentinc/cp-kafka-connect:5.5.7

WORKDIR /etc/kafka-connect/certs
WORKDIR /etc/kafka-connect-s3/connectors/properties

COPY ./files/certs/kafka.client.truststore.jks /etc/kafka-connect/certs
COPY ./scripts/entrypoint.sh /entrypoint.sh

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]
