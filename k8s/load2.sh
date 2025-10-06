 awk -v minikube_ip="$(minikube ip)" 'BEGIN {
  print "=== VARIABLE LOAD TEST ==="
  print "Target: " minikube_ip
  
  total_duration = 15 * 60  # в секундах
  start_time = systime()
  end_time = start_time + total_duration
  request_count = 0
  phase = 1
  
  printf "Running variable load test for %d seconds...", total_duration
  print "\nTime   | Phase   | Concurrent  | Description"
  print "-------|---------|-------------|------------"
  
  while(systime() < end_time) {
    elapsed = systime() - start_time
    progress = (elapsed / total_duration) * 100
    
    # Определяем фазу нагрузки на основе пройденного времени
    if (elapsed < total_duration/4) {          # нарастание
      phase = 1
      max_concurrent = 2 + int(rand() * 4)  # от 2 до 6
      description = "Ramp up"
    } else if (elapsed < total_duration / 3) {   # средняя нагрузка
      phase = 2
      # Случайное значение между 50 и 70
      max_concurrent = 10 + int(rand() * 10)
      description = "Medium variable"
    } else if (elapsed < total_duration/2) {   # пиковая нагрузка
      phase = 3
      # Случайное значение между 70 и 25
      max_concurrent = 20 + int(rand() * 20)
      description = "Peak load"
    } else if (elapsed < (total_duration / 2 + total_duration / 3)) {   # снижение
      phase = 4
      max_concurrent = 10 + 10  # от 25 до 15
      description = "Ramp down"
    } else {                      # 13-15 минут: низкая нагрузка
      phase = 5
      # Случайное значение между 1 и 5
      max_concurrent = 1 + int(rand() * 4)
      description = "Low load"
    }
    
    # Проверяем текущее количество параллельных запросов
    "jobs -r | wc -l" | getline current_jobs
    close("jobs -r | wc -l")
    
    # Запускаем новые запросы если есть место
    requests_to_launch = max_concurrent - current_jobs
    if (requests_to_launch > 0) {
      for(j=0; j<requests_to_launch; j++) {
        request_count++
        
        # Случайный тип запроса
        r = rand()
        if (r < 0.4) {
          # 40% - GET /health
          cmd = "curl -s -H \"Host: arch.homework\" http://" minikube_ip "/health > /dev/null &"
        } else if (r < 0.7) {
          # 30% - GET /users  
          cmd = "curl -s -H \"Host: arch.homework\" http://" minikube_ip "/users > /dev/null &"
        } else if (r < 0.9) {
          # 20% - POST /users
          cmd = "curl -s -H \"Host: arch.homework\" -X POST -H \"Content-Type: application/json\" -d '\''{\"name\":\"load_user" request_count "\",\"email\":\"load" request_count "@test.com\"}'\'' http://" minikube_ip "/users > /dev/null &"
        } else {
          # 10% - DELETE
          id = int(rand() * 50) + 1
          cmd = "curl -s -H \"Host: arch.homework\" -X DELETE http://" minikube_ip "/users/" id " > /dev/null &"
        }
        
        system(cmd)
      }
    }
    
    # Выводим статус каждые 5 секунд
    if (elapsed % 5 == 0) {
      minutes = int(elapsed / 60)
      seconds = elapsed % 60
      printf "[%02d:%02d] Phase %d: %2d concurrent (%s)\n", 
             minutes, seconds, phase, max_concurrent, description
    }
    
    system("sleep 1")
  }
  
  print "\nTest duration reached. Waiting for completion..."
  system("wait")
  printf "Final stats: %d total requests (%.1f RPS)\n", 
    request_count, request_count/total_duration
}'