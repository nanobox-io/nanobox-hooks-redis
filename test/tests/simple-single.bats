# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Production Container" {
  start_container "simple-single-production" "192.168.0.2"
}

@test "Configure Production Container" {
  run run_hook "simple-single-production" "configure" "$(payload configure)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Production ${service_name}" {
  run run_hook "simple-single-production" "start" "$(payload start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-production"
  wait_for_listening "simple-single-production" "192.168.0.2" ${default_port}
}

@test "Verify IP" {
  run docker exec simple-single-production bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 0 ] 
}

@test "Insert Production ${service_name} Data" {
  insert_test_data "simple-single-production" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-production" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Production ${service_name}" {
  run run_hook "simple-single-production" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-single-production" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-production"
  # Verify
  verify_stopped "simple-single-production"
}

@test "Verify No IP" {
  run docker exec simple-single-production bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 1 ] 
}

@test "Stop Production Container" {
  stop_container "simple-single-production"
}
