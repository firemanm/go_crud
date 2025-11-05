#!/bin/bash

set -e

echo "Starting PostgreSQL in Minikube..."

# Create data directory
minikube ssh "sudo mkdir -p /data/postgresql && sudo chmod 777 /data/postgresql"

# Apply PV, PVC 
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

# Install/upgrade postgresql in minikube
helm upgrade --install my-postgresql oci://registry-1.docker.io/bitnamicharts/postgresql -f pg_values.yaml --wait

echo "PostgreSQL installed successfully"

# Show info
echo "=== PV, PVC, Pods ==="
kubectl get pv,pvc,pods -l app.kubernetes.io/instance=my-postgresql

# Get the postgresql password
echo ""
echo "=== PostgreSQL Password ==="
POSTGRES_PASSWORD=$(kubectl get secret my-postgresql -o jsonpath='{.data.password}' | base64 -d)
echo "Password: $POSTGRES_PASSWORD"

# Stop any existing port-forward
echo ""
echo "=== Setting up Port Forward ==="
pkill -f "kubectl port-forward svc/my-postgresql" || true

# Port forward for local access
kubectl port-forward svc/my-postgresql 5432:5432 &
echo "Port forward started on 5432"

# Wait a moment for port-forward to establish
sleep 3

echo ""
echo "=== Connection Information ==="
echo "Host: localhost"
echo "Port: 5432"
echo "Username: postgres"
echo "Password: $POSTGRES_PASSWORD"
echo ""
echo "Quick connect:"
echo "  PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U user00 -d postgres"
echo ""
echo "Or use: ./pg-connect.sh"

