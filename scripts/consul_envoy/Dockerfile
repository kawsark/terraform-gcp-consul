FROM consul:1.7.3
FROM envoyproxy/envoy:v1.13.1
RUN cat /etc/os-release
COPY --from=0 /bin/consul /bin/consul
RUN apt-get update -y && apt-get install wget -y
RUN wget -O /bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /bin/dumb-init
ENTRYPOINT ["dumb-init"]