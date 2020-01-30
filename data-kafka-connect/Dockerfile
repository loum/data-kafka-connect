FROM confluentinc/cp-kafka-connect:5.3.2

RUN mkdir -p /etc/kafka-connect/certs \
  mkdir -p /etc/kafka-connect-s3/connectors/properties

COPY ./files/certs/kafka.client.truststore.jks /etc/kafka-connect/certs
COPY ./scripts/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
