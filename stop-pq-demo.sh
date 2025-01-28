#!/bin/bash
echo Delete ScaledObjects
kubectl delete -n pq-demo -f config/solace-pqdemo-scaler.yaml --ignore-not-found

echo Delete Pod 'solace-pqdemo-subscriber'
kubectl delete -f config/solace-pqdemo-subscriber.yaml --ignore-not-found
kubectl wait --for=delete deployment/pqdemo-subscriber --timeout=60s

echo Delete Secret 'pqdemo-solace-secrets'
kubectl delete secret -n pq-demo generic pqdemo-solace-secrets --ignore-not-found

echo Delete Secret 'solace-pqdemo-secrets'
kubectl delete secret -n pq-demo generic solace-pqdemo-secrets --ignore-not-found

echo Delete ConfigMap 'pqdemo-solace-configmap'
kubectl delete configmap -n pq-demo generic pqdemo-solace-configmap --ignore-not-found

echo Delete Namespace 'pq-demo'
kubectl delete namespace pq-demo
