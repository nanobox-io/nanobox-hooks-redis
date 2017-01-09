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
@test "Start Old Containers" {
  start_container "simple-redundant-old-primary" "192.168.0.2"
  start_container "simple-redundant-old-secondary" "192.168.0.3"
  start_container "simple-redundant-old-arbitrator" "192.168.0.4"
}

@test "Start New Containers" {
  start_container "simple-redundant-new-primary" "192.168.0.6"
  start_container "simple-redundant-new-secondary" "192.168.0.7"
  start_container "simple-redundant-new-arbitrator" "192.168.0.8"
}

# Configure containers
@test "Configure Old Containers" {
  run run_hook "simple-redundant-old-primary" "configure" "$(payload configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "configure" "$(payload configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "configure" "$(payload configure-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

# Configure containers
@test "Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "configure" "$(payload configure-primary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "configure" "$(payload configure-secondary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "configure" "$(payload configure-arbitrator-new)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Stop Old ${service_name} First" {
  run run_hook "simple-redundant-old-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New ${service_name} First" {
  run run_hook "simple-redundant-new-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Old Containers" {
  run run_hook "simple-redundant-old-primary" "redundant-configure" "$(payload redundant-configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-configure" "$(payload redundant-configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "redundant-configure" "$(payload redundant-configure-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Redundant Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "redundant-configure" "$(payload redundant-configure-primary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-configure" "$(payload redundant-configure-secondary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "redundant-configure" "$(payload redundant-configure-arbitrator-new)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Restop Old ${service_name}" {
  run run_hook "simple-redundant-old-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restop New ${service_name}" {
  run run_hook "simple-redundant-new-primary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Old ${service_name} Are Stopped" {
  wait_for_stop "simple-redundant-old-primary"
  verify_stopped "simple-redundant-old-primary"
  wait_for_stop "simple-redundant-old-secondary"
  verify_stopped "simple-redundant-old-secondary"
}

@test "Start Old ${service_name} Cluster" {
  run run_hook "simple-redundant-old-primary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "redundant-start-arbitrator" "$(payload redundant-start-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_running "simple-redundant-old-primary"
  wait_for_listening "simple-redundant-old-primary" "192.168.0.2" ${default_port}
  wait_for_running "simple-redundant-old-secondary"
  wait_for_listening "simple-redundant-old-secondary" "192.168.0.3" ${default_port}
  wait_for_arbitrator_running "simple-redundant-old-arbitrator"
}

@test "Ensure New ${service_name} Are Stopped" {
  wait_for_stop "simple-redundant-new-primary"
  verify_stopped "simple-redundant-new-primary"
  wait_for_stop "simple-redundant-new-secondary"
  verify_stopped "simple-redundant-new-secondary"
}

@test "Insert Old ${service_name} Data" {
  insert_test_data "simple-redundant-old-primary" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-redundant-old-primary" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Run Import Prep" {
  if [ ! -f ../src/import-prep ]; then
    skip "import-prep hook isn't defined"
  fi 
  run run_hook "simple-redundant-new-primary" "redundant-import-prep" "$(payload redundant-import-prep-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-import-prep" "$(payload redundant-import-prep-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Run Export Prep" {
  if [ ! -f ../src/Export-prep ]; then
    skip "Export-prep hook isn't defined"
  fi 
  run run_hook "simple-redundant-old-primary" "redundant-export-prep" "$(payload redundant-export-prep-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-export-prep" "$(payload redundant-export-prep-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Import Live ${service_name}" {
  if [ ! -f ../src/import-live ]; then
    skip "import-live hook isn't defined"
  fi 
  run run_hook "simple-redundant-new-primary" "redundant-import-live" "$(payload redundant-import-live-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-import-live" "$(payload redundant-import-live-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Export Live ${service_name}" {
  if [ ! -f ../src/export-live ]; then
    skip "export-live hook isn't defined"
  fi 
  run run_hook "simple-redundant-old-primary" "redundant-export-live" "$(payload redundant-export-live-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-export-live" "$(payload redundant-export-live-secondary)"
  echo_lines
  [ "$status" -eq 0 ]

  run docker exec "simple-redundant-new-primary" bash -c "[[ ! -d /root/data ]]"
  [ "$status" -eq 0 ]

  run docker exec "simple-redundant-new-secondary" bash -c "[[ ! -d /root/data ]]"
  [ "$status" -eq 0 ]
}

@test "Update Old ${service_name} Data" {
  update_test_data "simple-redundant-old-primary" "192.168.0.2" ${default_port} "mykey" "date"
  verify_test_data "simple-redundant-old-primary" "192.168.0.2" ${default_port} "mykey" "date"
}

@test "Stop Old ${service_name}" {
  run run_hook "simple-redundant-old-primary" "redundant-stop" "$(payload redundant-stop)"
  [ "$status" -eq 0 ]
    run run_hook "simple-redundant-old-secondary" "redundant-stop" "$(payload redundant-stop)"
  [ "$status" -eq 0 ]
    run run_hook "simple-redundant-old-arbitrator" "redundant-stop-arbitrator" "$(payload redundant-stop-arbitrator)"
  [ "$status" -eq 0 ]
  wait_for_stop "simple-redundant-old-primary"
  verify_stopped "simple-redundant-old-primary"
  wait_for_stop "simple-redundant-old-secondary"
  verify_stopped "simple-redundant-old-secondary"
}

@test "Export Final ${service_name}" {
  if [ ! -f ../src/export-final ]; then
    skip "export-final hook isn't defined"
  fi 
  run run_hook "simple-redundant-old-primary" "redundant-export-final" "$(payload redundant-export-final-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-export-final" "$(payload redundant-export-final-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
  
  run docker exec "simple-redundant-new-primary" bash -c "[[ ! -d /root/data ]]"
  [ "$status" -eq 0 ]

  run docker exec "simple-redundant-new-secondary" bash -c "[[ ! -d /root/data ]]"
  [ "$status" -eq 0 ]
}

@test "Import Final ${service_name}" {
  if [ ! -f ../src/import-final ]; then
    skip "import-final hook isn't defined"
  fi 
  run run_hook "simple-redundant-new-primary" "redundant-import-final" "$(payload redundant-import-final-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-import-final" "$(payload redundant-import-final-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Export Clean" {
  if [ ! -f ../src/export-clean ]; then
    skip "export-clean hook isn't defined"
  fi 
  run run_hook "simple-redundant-old-primary" "redundant-export-clean" "$(payload redundant-export-clean-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-export-clean" "$(payload redundant-export-clean-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Import Clean" {
  if [ ! -f ../src/import-clean ]; then
    skip "import-clean hook isn't defined"
  fi 
  run run_hook "simple-redundant-new-primary" "redundant-import-clean" "$(payload redundant-import-clean-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-import-clean" "$(payload redundant-import-clean-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start New ${service_name} Cluster" {
  run run_hook "simple-redundant-new-primary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-start" "$(payload redundant-start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "redundant-start-arbitrator" "$(payload redundant-start-arbitrator)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_running "simple-redundant-new-primary"
  wait_for_listening "simple-redundant-new-primary" "192.168.0.6" ${default_port}
  wait_for_running "simple-redundant-new-secondary"
  wait_for_listening "simple-redundant-new-secondary" "192.168.0.7" ${default_port}
  wait_for_arbitrator_running "simple-redundant-new-arbitrator"
}

@test "Verify New Primary ${service_name} Data" {
  verify_test_data "simple-redundant-new-primary" "192.168.0.6" ${default_port} "mykey" "date"
}

@test "Verify New Secondary ${service_name} Data" {
  verify_test_data "simple-redundant-new-secondary" "192.168.0.6" ${default_port} "mykey" "date"
}

# Stop containers
@test "Stop Old Containers" {
  stop_container "simple-redundant-old-primary"
  stop_container "simple-redundant-old-secondary"
  stop_container "simple-redundant-old-arbitrator"
}

@test "Stop New Containers" {
  stop_container "simple-redundant-new-primary"
  stop_container "simple-redundant-new-secondary"
  stop_container "simple-redundant-new-arbitrator"
}