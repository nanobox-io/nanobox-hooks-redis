# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Old Container" {
  start_container "simple-single-old" "192.168.0.2"
}

@test "Configure Old Container" {
  run run_hook "simple-single-old" "configure" "$(payload configure)"
  [ "$status" -eq 0 ] 
}

@test "Start Old ${service_name}" {
  run run_hook "simple-single-old" "start" "$(payload start)"
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-old"
  wait_for_listening "simple-single-old" "192.168.0.2" ${default_port}
  [ "$status" -eq 0 ]
}

@test "Insert Old ${service_name} Data" {
  insert_test_data "simple-single-old" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-old" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Start New Container" {
  start_container "simple-single-new" "192.168.0.4"
}

@test "Configure New Container" {
  run run_hook "simple-single-new" "configure" "$(payload configure)"
  [ "$status" -eq 0 ] 
}

@test "Start New ${service_name}" {
  run run_hook "simple-single-new" "start" "$(payload start)"
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-new"
  wait_for_listening "simple-single-new" "192.168.0.4" ${default_port}
  [ "$status" -eq 0 ] 
}

@test "Stop New ${service_name}" {
  run run_hook "simple-single-new" "stop" "$(payload stop)"
  [ "$status" -eq 0 ]
  wait_for_stop simple-single-new
  # Verify
  verify_stopped simple-single-new
}

@test "Run Import Prep" {
  if [ ! -f ../src/import-prep ]; then
    skip "import-prep hook isn't defined"
  fi 
  run run_hook "simple-single-new" "import-prep" "$(payload import-prep)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Run Export Prep" {
  if [ ! -f ../src/Export-prep ]; then
    skip "Export-prep hook isn't defined"
  fi 
  run run_hook "simple-single-old" "export-prep" "$(payload export-prep)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Import Live ${service_name}" {
  if [ ! -f ../src/import-live ]; then
    skip "import-live hook isn't defined"
  fi 
  run run_hook "simple-single-new" "import-live" "$(payload import-live)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Export Live ${service_name}" {
  if [ ! -f ../src/export-live ]; then
    skip "export-live hook isn't defined"
  fi 
  run run_hook "simple-single-old" "export-live" "$(payload export-live)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Update Old ${service_name} Data" {
  update_test_data "simple-single-old" "192.168.0.2" ${default_port} "mykey" "date"
  verify_test_data "simple-single-old" "192.168.0.2" ${default_port} "mykey" "date"
}

@test "Stop Old ${service_name}" {
  run run_hook "simple-single-old" "stop" "$(payload stop)"
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-old"
  # Verify
  verify_stopped "simple-single-old"
}

@test "Export Final ${service_name}" {
  if [ ! -f ../src/export-final ]; then
    skip "export-final hook isn't defined"
  fi 
  run run_hook "simple-single-old" "export-final" "$(payload export-final)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Import Final ${service_name}" {
  if [ ! -f ../src/import-final ]; then
    skip "import-final hook isn't defined"
  fi 
  run run_hook "simple-single-new" "import-final" "$(payload import-final)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Export Clean" {
  if [ ! -f ../src/export-clean ]; then
    skip "export-clean hook isn't defined"
  fi 
  run run_hook "simple-single-new" "export-clean" "$(payload export-clean)"
  [ "$status" -eq 0 ]
}

@test "Import Clean" {
  if [ ! -f ../src/import-clean ]; then
    skip "import-clean hook isn't defined"
  fi 
  run run_hook "simple-single-new" "import-clean" "$(payload import-clean)"
  [ "$status" -eq 0 ]
}

@test "Restart New ${service_name}" {
  run run_hook "simple-single-new" "start" "$(payload start)"
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-new"
  wait_for_listening "simple-single-new" "192.168.0.4" ${default_port}
}

@test "Verify New ${service_name} Data" {
verify_test_data "simple-single-new" "192.168.0.4" ${default_port} "mykey" "date"
}

@test "Stop Old Container" {
  stop_container "simple-single-old"
}

@test "Stop New Container" {
  stop_container "simple-single-new"
}