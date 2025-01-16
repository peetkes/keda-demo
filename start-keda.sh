#!/bin/bash

echo Create Namespace 'keda'
kubectl create namespace keda

echo Install Keda
helm install keda kedacore/keda -n keda

kubectl wait -n keda --for=condition=Ready -l app.kubernetes.io/instance=keda --timeout=120s --all pods
