awk 'BEGIN {
  # Получаем IP minikube один раз
  "minikube ip" | getline minikube_ip
  close("minikube ip")
  
  print "Using Minikube IP: " minikube_ip
  
  endpoints[1] = "GET /health"
  endpoints[2] = "GET /users" 
  endpoints[3] = "POST /users"
  endpoints[4] = "DELETE /users/1"
  
  for(i=1; i<=1000; i++) {
    method = endpoints[int(rand()*4)+1]
    split(method, parts, " ")
    http_method = parts[1]
    path = parts[2]
    
    if(http_method == "POST") {
      cmd = "curl -H \"Host: arch.homework\" -X POST -H \"Content-Type: application/json\" -d '\''{\"name\":\"user" i "\",\"email\":\"test" i "@test.com\"}'\'' http://" minikube_ip path " &"
    } else if(http_method == "DELETE") {
      id = int(rand()*10) + 1
      cmd = "curl -H \"Host: arch.homework\" -X DELETE http://" minikube_ip "/users/" id " &"
    } else {
      cmd = "curl -H \"Host: \"Host: arch.homework\" -X " http_method " http://" minikube_ip path " &"
    }
    
    print "Executing: " cmd
    system(cmd)
    system("sleep 0.05")
  }
  print "Load test completed"
}'