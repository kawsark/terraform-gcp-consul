#!/bin/bash
pwd 

crt_file=$(ls *-ca.crt.pem) && echo ${crt_file}
kubectl delete secret consul-ca-cert &> /dev/null
kubectl create secret generic consul-ca-cert --from-file="tls.crt=./${crt_file}"
kubectl describe secret consul-ca-cert

key_file=$(ls *-ca.key.pem) && echo ${key_file}
kubectl delete secret consul-ca-key &> /dev/null
kubectl create secret generic consul-ca-key --from-file="tls.key=./${key_file}"
kubectl describe secret consul-ca-key
