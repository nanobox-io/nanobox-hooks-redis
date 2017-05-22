# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

# Start containers
@test "Start Primary Container" {
  start_container "simple-redundant-primary" "192.168.0.2"
}

@test "Start Secondary Container" {
  start_container "simple-redundant-secondary" "192.168.0.3"
}

@test "Start Arbitrator Container" {
  start_container "simple-redundant-arbitrator" "192.168.0.4"
}

# Configure containers
@test "Configure Primary Container" {
  run run_hook "simple-redundant-primary" "configure" "$(payload configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "configure" "$(payload configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Arbitrator Container" {
  run run_hook "simple-redundant-arbitrator" "configure" "$(payload configure-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 5
}

@test "Stop Primary ${service_name}" {
  run run_hook "simple-redundant-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Secondary ${service_name}" {
  run run_hook "simple-redundant-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure ${service_name} Is Stopped" {
  wait_for_stop "simple-redundant-primary"
  verify_stopped "simple-redundant-primary"
  wait_for_stop "simple-redundant-secondary"
  verify_stopped "simple-redundant-secondary"
}

@test "Redundant Configure Primary Container" {
  run run_hook "simple-redundant-primary" "redundant-configure" "$(payload redundant-configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "redundant-configure" "$(payload redundant-configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Arbitrator Container" {
  run run_hook "simple-redundant-arbitrator" "redundant-configure" "$(payload redundant-configure-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Restop Primary ${service_name}" {
  run run_hook "simple-redundant-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restop Secondary ${service_name}" {
  run run_hook "simple-redundant-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure ${service_name} Is Stopped Again" {
  wait_for_stop "simple-redundant-primary"
  verify_stopped "simple-redundant-primary"
  wait_for_stop "simple-redundant-secondary"
  verify_stopped "simple-redundant-secondary"
}

@test "Start Primary ${service_name}" {
  run run_hook "simple-redundant-primary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Secondary ${service_name}" {
  run run_hook "simple-redundant-secondary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Arbitrator" {
  run run_hook "simple-redundant-arbitrator" "redundant-start-arbitrator" "$(payload redundant-start-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure ${service_name} Primary Is Started" {
  wait_for_running "simple-redundant-primary"
  wait_for_listening "simple-redundant-primary" "192.168.0.2" ${default_port}
}

@test "Ensure ${service_name} Secondary Is Started" {
  wait_for_running "simple-redundant-secondary"
  wait_for_listening "simple-redundant-secondary" "192.168.0.3" ${default_port}
}

@test "Ensure Arbitrator Is Started" {
  wait_for_arbitrator_running "simple-redundant-arbitrator"
}

@test "Insert Primary ${service_name} Data" {
  insert_test_data "simple-redundant-primary" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-redundant-primary" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Insert Secondary ${service_name} Data" {
  if [ "$multi_master" = "false" ]; then
    skip
  fi
  insert_test_data "simple-redundant-secondary" "192.168.0.3" ${default_port} "mykey2" "date"
  verify_test_data "simple-redundant-secondary" "192.168.0.3" ${default_port} "mykey2" "date"
}

@test "Verify Primary ${service_name} Data" {
  verify_test_data "simple-redundant-primary" "192.168.0.2" ${default_port} "mykey" "data"
  if [ ! "$multi_master" = "false" ]; then
    verify_test_data "simple-redundant-primary" "192.168.0.2" ${default_port} "mykey2" "date"
  fi
}

# Verify IP
@test "Verify Primary IP" {
  run docker exec "simple-redundant-primary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify Secondary IP" {
  run docker exec "simple-redundant-secondary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 1 ]
}

@test "Verify Arbitrator IP" {
  run docker exec "simple-redundant-arbitrator" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 1 ]
}

# Stop containers
@test "Stop Primary Container" {
  stop_container "simple-redundant-primary"
}

@test "Stop Secondary Container" {
  stop_container "simple-redundant-secondary"
}

@test "Stop Arbitrator Container" {
  stop_container "simple-redundant-arbitrator"
}