#!/bin/bash

# Get the password
PASSWORD=$(kubectl get secret my-postgresql -o jsonpath='{.data.password}' | base64 -d)

# Connect to PostgreSQL
echo "Connecting to PostgreSQL..."
PGPASSWORD=$PASSWORD psql -h localhost -U user00 -d postgres