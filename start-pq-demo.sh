#!/bin/bash

echo Configure the Solace PubSubPlus Event Broker
kubectl exec kedalab-helper -n solace -- /pqdemo-config/config_solace.sh

echo Create Namespace 'pq-demo'
kubectl create namespace pq-demo

echo Create Secret 'pqdemo-solace-secret'
kubectl delete secret -n pq-demo generic pqdemo-solace-secret --ignore-not-found
kubectl create secret -n pq-demo generic pqdemo-solace-secret \
  --from-literal=SEMP_USER=admin \
  --from-literal=SEMP_PASSWORD=admin \
  --save-config --dry-run=client -o yaml | kubectl apply -f -

echo Create Secret 'solace-pqdemo-secrets'
kubectl delete secret -n pq-demo generic solace-pqdemo-secrets --ignore-not-found
kubectl apply -f config/solace-pqdemo-secrets.yaml

echo Create Pod 'pqdemo-subscriber'
kubectl apply -f config/solace-pqdemo-subscriber.yaml

kubectl wait -n pq-demo --for=condition=Ready -l app=pqdemo-subscriber --timeout=120s --all pods

echo Create Scaler 'pqdemo-scaler'
kubectl apply -f config/solace-pqdemo-scaler.yaml
