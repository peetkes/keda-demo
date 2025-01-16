#!/bin/bash

echo Uninstall Keda
helm uninstall keda -n keda

echo Delete Namespace 'keda'
kubectl delete namespace keda

