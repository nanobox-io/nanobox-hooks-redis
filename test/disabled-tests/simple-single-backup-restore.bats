# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Container" {
  start_container "backup-restore" "192.168.0.2"
  run run_hook "backup-restore" "configure" "$(payload configure)"
  echo_lines
  [ "$status" -eq 0 ] 
  run run_hook "backup-restore" "start" "$(payload start)"
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "backup-restore"
  wait_for_listening "backup-restore" "192.168.0.2" ${default_port}
  # [ "$status" -eq 0 ]
}

@test "Start Backup Container" {
  start_container "backup" "192.168.0.9"
  # generate some keys
  run run_hook "backup" "configure" "$(payload configure)"
  echo_lines
  [ "$status" -eq 0 ]

  # start ssh server
  run run_hook "backup" "import-prep" "$(payload import-prep)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "backup" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Insert ${service_name} Data" {
  insert_test_data "backup-restore" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "backup-restore" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Backup" {
  run run_hook "backup-restore" "backup" "$(payload backup)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Update ${service_name} Data" {
  update_test_data "backup-restore" "192.168.0.2" ${default_port} "mykey" "date"
  verify_test_data "backup-restore" "192.168.0.2" ${default_port} "mykey" "date"
}

@test "Restore" {
  run run_hook "backup-restore" "restore" "$(payload restore)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify ${service_name} Data" {
  verify_test_data "backup-restore" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Container" {
  stop_container "backup-restore"
}

@test "Stop Backup Container" {
  stop_container "backup"
}