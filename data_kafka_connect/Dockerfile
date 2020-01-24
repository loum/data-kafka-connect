FROM confluentinc/cp-kafka-connect:5.3.2

RUN mkdir -p /etc/kafka-connect/certs \
  mkdir -p /etc/kafka-connect-s3/lfs/connectors/properties

COPY ./files/certs/kafka.client.truststore.jks /etc/kafka-connect/certs
COPY ./files/connectors/properties/*s3.properties.json /etc/kafka-connect-s3/lfs/connectors/properties

RUN apt-get update -yqq && apt-get install jq -yqq
RUN pip install --upgrade pip && pip install backoff

COPY ./scripts/bootstrap /bootstrap
COPY ./scripts/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
