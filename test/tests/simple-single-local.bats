# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Local Container" {
  start_container "simple-single-local" "192.168.0.2"
}

@test "Configure Local Container" {
  run run_hook "simple-single-local" "configure" "$(payload configure-local)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Local ${service_name}" {
  run run_hook "simple-single-local" "start" "$(payload start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-local"
  wait_for_listening "simple-single-local" "192.168.0.2" ${default_port}
}

@test "Verify IP" {
  run docker exec simple-single-local bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 0 ] 
}

@test "Insert Local ${service_name} Data" {
  insert_test_data "simple-single-local" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-local" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Local ${service_name}" {
  run run_hook "simple-single-local" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-local"
  # Verify
  verify_stopped "simple-single-local"
}

@test "Verify No IP" {
  run docker exec simple-single-local bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 1 ] 
}

@test "Stop Local Container" {
  stop_container "simple-single-local"
}
