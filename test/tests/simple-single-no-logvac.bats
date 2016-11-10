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
  start_container "simple-single-no-logvac" "192.168.0.2"
}

@test "Configure Local Container" {
  run run_hook "simple-single-no-logvac" "configure" "$(payload configure-no-logvac)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Local ${service_name}" {
  run run_hook "simple-single-no-logvac" "start" "$(payload start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-no-logvac"
  wait_for_listening "simple-single-no-logvac" "192.168.0.2" ${default_port}
}

@test "Insert Local ${service_name} Data" {
  insert_test_data "simple-single-no-logvac" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-no-logvac" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Local ${service_name}" {
  run run_hook "simple-single-no-logvac" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-no-logvac"
  # Verify
  verify_stopped "simple-single-no-logvac"
}

@test "Stop Local Container" {
  stop_container "simple-single-no-logvac"
}
