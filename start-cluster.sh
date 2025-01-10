#!/bin/bash
echo Create Namespace 'keda'
kubectl create namespace keda

echo Install Keda
helm install keda kedacore/keda -n keda

kubectl wait -n keda --for=condition=Ready -l app.kubernetes.io/instance=keda --timeout=120s --all pods

echo Create Namespace 'solace'
kubectl create namespace solace

echo Deploy Solace PubSubPlus Eeven Broker
helm install kedalab solacecharts/pubsubplus-dev -f values-mac.yaml -n solace \
  --set solace.usernameAdminPassword=admin \
  --set storage.persistent=false

kubectl wait -n solace --for=condition=Ready -l app.kubernetes.io/name=pubsubplus-dev --timeout=120s --all pods

echo Create Secret 'kedalab-solace-secret'
kubectl delete secret -n solace generic kedalab-solace-secret --ignore-not-found
kubectl create secret -n solace generic kedalab-solace-secret \
  --from-literal=SEMP_USER=admin \
  --from-literal=SEMP_PASSWORD=admin \
  --save-config --dry-run=client -o yaml | kubectl apply -f -

echo Create ConfigMap 'kedalab-solace-configmap'
kubectl delete configmap -n solace generic kedalab-solace-configmap --ignore-not-found
kubectl create configmap -n solace kedalab-solace-configmap \
  --from-file config/broker-config \
  --save-config --dry-run=client -o yaml | kubectl apply -f -

echo Create Pod 'kedalab-helper'
kubectl apply -f config/kedalab-helper.yaml

kubectl wait -n solace --for=condition=Ready -l app=kedalab-helper --timeout=120s --all pods

echo Configure the Solace PubSubPlus Event Broker
kubectl exec kedalab-helper -n solace -- /keda-config/config_solace.sh

echo Create Secret 'solace-consumer-secret'
kubectl create secret -n solace generic solace-consumer-secret \
  --from-literal=solace.client.username=consumer_user \
  --from-literal=solace.client.pwd=consumer_pwd \
  --save-config --dry-run=client -o yaml | kubectl apply -f -

echo Create ConfigMap 'solace-consumer-configmap'
kubectl create configmap -n solace solace-consumer-configmap \
  --from-literal=solace.client.port=55554 \
  --save-config --dry-run=client -o yaml | kubectl apply -f -

echo Create Pod 'solace-consumer'
kubectl apply -f config/solace-consumer.yaml

kubectl wait -n solace --for=condition=Ready -l app=solace-consumer --timeout=120s --all pods
