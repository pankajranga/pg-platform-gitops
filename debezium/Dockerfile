# Starts from Debezium's own image, which we already confirmed works correctly
# as a plain Kubernetes Deployment (unlike trying to run it through Strimzi's
# KafkaConnect operator, which failed earlier today).
FROM quay.io/debezium/connect:3.0

USER root

# Debezium's image logs "Plugins are loaded from /kafka/connect" on startup -
# each subfolder under this path is treated as one connector plugin.
RUN mkdir -p /kafka/connect/bigquery-sink /tmp/bq-extract && \
    curl -fSL https://github.com/Aiven-Open/bigquery-connector-for-apache-kafka/releases/download/v2.14.0/bigquery-connector-for-apache-kafka-2.14.0.tar -o /tmp/bq-connector.tar && \
    tar -xf /tmp/bq-connector.tar -C /tmp/bq-extract && \
    find /tmp/bq-extract -name '*.jar' -exec cp {} /kafka/connect/bigquery-sink/ \; && \
    rm -rf /tmp/bq-connector.tar /tmp/bq-extract

# NOTE: staying as root for simplicity/time today, rather than chasing the
# exact non-root UID Debezium's base image expects. A logged simplification,
# consistent with other pragmatic shortcuts taken this week (static AR key,
# postgres superuser for Debezium) - worth hardening in a real deployment.