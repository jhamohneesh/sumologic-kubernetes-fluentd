# TODO: Use BuildKit cache from previously pushed image
# TODO: Check if it's possible to use ruby:2.6 Docker image here
FROM fluent/fluentd:v1.11.5-debian-1.0 AS builder

# Use root account to use apt
USER root

# Dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        curl \
        g++ \
        gcc \
        libc-dev \
        libsnappy-dev \
        make \
        ruby-dev \
        sudo \
        unzip

# Fluentd plugin dependencies
RUN gem install \
        concurrent-ruby:1.1.5 \
        google-protobuf:3.9.2 \
        kubeclient:4.9.1 \
        lru_redux:1.1.0 \
        snappy:0.0.17

# FluentD plugins to allow customers to forward data if needed to various cloud providers
RUN gem install \
        fluent-plugin-s3
        # TODO: Support additional cloud providers
        # && gem install fluent-plugin-google-cloud \
        # && gem install fluent-plugin-azure-storage-append-blob

# FluentD plugins from RubyGems
RUN gem install \
        fluent-plugin-systemd:1.0.2 \
        fluent-plugin-record-modifier:2.0.1 \
        fluent-plugin-sumologic_output:1.7.1 \
        fluent-plugin-concat:2.4.0 \
        fluent-plugin-rewrite-tag-filter:2.2.0 \
        fluent-plugin-prometheus:1.6.1

WORKDIR /sumologic-kubernetes-fluentd

COPY fluent-plugin-datapoint/ ./fluent-plugin-datapoint
RUN cd fluent-plugin-datapoint \
 && gem build fluent-plugin-datapoint.gemspec -o ../fluent-plugin-datapoint.gem \
 && cd ..

COPY fluent-plugin-enhance-k8s-metadata/ ./fluent-plugin-enhance-k8s-metadata
RUN cd fluent-plugin-enhance-k8s-metadata \
 && gem build fluent-plugin-enhance-k8s-metadata.gemspec -o ../fluent-plugin-enhance-k8s-metadata.gem \
 && cd ..

COPY fluent-plugin-events/ ./fluent-plugin-events
RUN cd fluent-plugin-events \
 && gem build fluent-plugin-events.gemspec -o ../fluent-plugin-events.gem \
 && cd ..

COPY fluent-plugin-kubernetes-metadata-filter ./fluent-plugin-kubernetes-metadata-filter
RUN cd fluent-plugin-kubernetes-metadata-filter \
 && gem build fluent-plugin-kubernetes-metadata-filter.gemspec -o ../fluent-plugin-kubernetes-metadata-filter.gem \
 && cd ..

COPY fluent-plugin-kubernetes-sumologic/ ./fluent-plugin-kubernetes-sumologic
RUN cd fluent-plugin-kubernetes-sumologic \
 && gem build fluent-plugin-kubernetes-sumologic.gemspec -o ../fluent-plugin-kubernetes-sumologic.gem \
 && cd ..

COPY fluent-plugin-prometheus-format ./fluent-plugin-prometheus-format
RUN cd fluent-plugin-prometheus-format \
 && gem build fluent-plugin-prometheus-format.gemspec -o ../fluent-plugin-prometheus-format.gem \
 && cd ..

COPY fluent-plugin-protobuf/ ./fluent-plugin-protobuf
RUN cd fluent-plugin-protobuf \
 && gem build fluent-plugin-protobuf.gemspec -o ../fluent-plugin-protobuf.gem \
 && cd ..

RUN gem install \
        --local fluent-plugin-prometheus-format \
        --local fluent-plugin-kubernetes-metadata-filter \
        --local fluent-plugin-kubernetes-sumologic \
        --local fluent-plugin-enhance-k8s-metadata \
        --local fluent-plugin-datapoint \
        --local fluent-plugin-protobuf \
        --local fluent-plugin-events

RUN rm -rf /usr/local/bundle/cache/* \
 && find /usr/local/bundle/ -name "*.o" | xargs rm

FROM fluent/fluentd:v1.11.5-debian-1.0

USER root

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        libsnappy-dev \
        curl \
        jq \
 && rm -rf /var/lib/apt/lists/ \
 && rm -rf /var/lib/dpkg/info/

COPY --from=builder --chown=fluent:fluent /usr/local/bundle /usr/local/bundle
COPY ./entrypoint.sh /bin/

USER fluent

ARG BUILD_TAG=latest
ENV TAG $BUILD_TAG