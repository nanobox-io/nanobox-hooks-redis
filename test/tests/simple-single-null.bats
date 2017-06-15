# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Null Container" {
  start_container "simple-single-null" "192.168.0.2"
}

@test "Configure Null Container" {
  run run_hook "simple-single-null" "configure" "$(payload configure-null)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Null ${service_name}" {
  run run_hook "simple-single-null" "start" "$(payload start-null)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-null"
  wait_for_listening "simple-single-null" "192.168.0.2" ${default_port}
}

@test "Insert Null ${service_name} Data" {
  insert_test_data "simple-single-null" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-null" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Null ${service_name}" {
  run run_hook "simple-single-null" "stop" "$(payload stop-null)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-null"
  # Verify
  verify_stopped "simple-single-null"
}

@test "Stop Null Container" {
  stop_container "simple-single-null"
}
