Steps to build the consul_envoy image

```
tag=v1.7.3-v1.13.1
docker build -t <username>/consul-envoy:$tag .
docker push <username>/consul-envoy:$tag
```