#!/bin/bash

echo "Cleaning up PostgreSQL installation ..."

helm uninstall my-postgresql
kubectl delete pvc pg-pvc
kubectl delete pv pg-pv
pkill -f "my-postgresql"

echo "Cleanup completed"