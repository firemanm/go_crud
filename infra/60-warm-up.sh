#!/bin/bash

MINIKUBE_IP=$(minikube ip)
echo "🚀 Starting load test to: $MINIKUBE_IP"
echo "🎯 Target host: arch.homework"

show_users() {
    echo "📊 Current users in database:"
    curl -s -H "Host: arch.homework" "http://$MINIKUBE_IP/users" | jq -r '
        if length > 0 then
            "First 3 users:",
            (.[0:3] | .[] | "  ID: \(.id) | Name: \(.name) | Email: \(.email) | Created: \(.created_at)"),
            "\nLast 3 users:",
            (.[-3:] | .[] | "  ID: \(.id) | Name: \(.name) | Email: \(.email) | Created: \(.created_at)"),
            "\nTotal users: \(length)"
        else
            "No users in database"
        end
    '
    echo "----------------------------------------"
}

TOTAL_REQUESTS=500
BATCH_SIZE=$((TOTAL_REQUESTS / 10))
CONCURRENT_LIMIT=10

echo "📈 Before load test:"
curl -H "Host: arch.homework" http://$(minikube ip)/users | jq '{
  unique_emails: (map(.email) | unique | length)
}'
counter=0

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    ((counter++))
    
    case $((RANDOM % 4)) in
        0)
            curl -s -H "Host: arch.homework" -X GET "http://$MINIKUBE_IP/health" > /dev/null 2>&1 &
            ;;
        1)
            curl -s -H "Host: arch.homework" -X GET "http://$MINIKUBE_IP/users" > /dev/null 2>&1 &
            ;;
        2)
            curl -s -H "Host: arch.homework" -X POST \
                -H "Content-Type: application/json" \
                -d "{\"name\":\"user$i\",\"email\":\"test$i@test.com\"}" \
                "http://$MINIKUBE_IP/users" > /dev/null 2>&1 &
            ;;
        3)
            id=$((RANDOM % 100 + 1))
            curl -s -H "Host: arch.homework" -X DELETE "http://$MINIKUBE_IP/users/$id" > /dev/null 2>&1 &
            ;;
    esac

    # Ограничение concurrent запросов
    if (( counter % CONCURRENT_LIMIT == 0 )); then
        wait
        sleep 0.1
    fi

    # Прогресс
    if (( i % BATCH_SIZE == 0 )); then
        echo "✅ Sent $i/$TOTAL_REQUESTS requests..."
    fi
    
    sleep 0.03
done

# Финальное ожидание
wait
echo "🎉 Load test completed! $TOTAL_REQUESTS requests sent."

wait

echo ""
echo "📊 After load test:"
# show_users

# curl -H "Host: arch.homework" http://$(minikube ip)/users | jq
curl -H "Host: arch.homework" http://$(minikube ip)/users | jq '{
  total: length,
  first_created: min_by(.created_at).created_at,
  last_created: max_by(.created_at).created_at,
  unique_emails: (map(.email) | unique | length)
}'
