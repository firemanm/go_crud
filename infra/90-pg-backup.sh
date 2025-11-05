#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_${DATE}.sql"

echo "Creating backup: $BACKUP_FILE"

# PGPASSWORD=Pass@word1 pg_dump -h localhost -U user00 -d mydb1 > $BACKUP_FILE

POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')
echo "Creating backup from pod: $POD_NAME"
kubectl exec $POD_NAME -- bash -c "PGPASSWORD=Pass@word1 pg_dump -U user00 -d mydb1 -h localhost" > $BACKUP_FILE

echo "Backup created: $BACKUP_FILE"
ls -lh $BACKUP_FILE