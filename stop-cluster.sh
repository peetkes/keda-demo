#!/bin/bash
echo Delete ScaledObjects
kubectl delete -n solace -f config/scaledobject-complete-hpa.yaml --ignore-not-found
kubectl delete -n solace -f config/solace-pqdemo-scaler.yaml --ignore-not-found

echo Delete Pod 'solace-consumer'
kubectl delete -f config/solace-consumer.yaml --ignore-not-found
kubectl wait --for=delete deployment/solace-consumer --timeout=60s

echo Delete Pod 'solace-pqdemo-subscriber'
kubectl delete -f config/solace-pqdemo-subscriber.yaml --ignore-not-found
kubectl wait --for=delete deployment/pqdemo-subscriber --timeout=60s

echo Delete Pod 'kedalab-helper'
kubectl delete -f config/kedalab-helper.yaml --ignore-not-found
kubectl wait --for=delete pod/kedalab-helper --timeout=60s

echo Uninstall PubSubPlus Event Broker
helm uninstall kedalab -n solace

echo Delete Secret 'kedalab-solace-secret'
kubectl delete secret -n solace generic kedalab-solace-secret --ignore-not-found

echo Delete Secret 'solace-pqdemo-secret'
kubectl delete secret -n solace generic solace-pqdemo-secret --ignore-not-found

echo Delete ConfigMap 'kedalab-solace-configmap'
kubectl delete configmap -n solace generic kedalab-solace-configmap --ignore-not-found

echo Delete Namespace 'solace'
kubectl delete namespace solace

echo Uninstall Keda
helm uninstall keda -n keda

echo Delete Namespace 'keda'
kubectl delete namespace keda

