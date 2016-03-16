# source docker helpers
. util/docker.sh

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
  run run_hook "simple-single-old" "configure" "$(payload default/configure-production)"

  [ "$status" -eq 0 ] 
}

@test "Start Old Redis" {
  run run_hook "simple-single-old" "start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [r]edis-server"
  [ "$status" -eq 0 ]
  until docker exec "simple-single-old" bash -c "nc 192.168.0.2 6379 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Old Redis Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Start New Container" {
  start_container "simple-single-new" "192.168.0.3"
}

@test "Configure New Container" {
  run run_hook "simple-single-new" "configure" "$(payload default/configure-production)"
  [ "$status" -eq 0 ] 
}

@test "Start New Redis" {
  run run_hook "simple-single-new" "start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [r]edis-server"
  [ "$status" -eq 0 ] 
}

@test "Stop New Redis" {
  run run_hook "simple-single-new" "stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-new" bash -c "ps aux | grep [r]edis-server"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [r]edis-server"
  [ "$status" -eq 1 ] 
}

@test "Start New SSHD" {
  # start ssh server
  run run_hook "simple-single-new" "import-prep" "$(payload default/import-prep)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-new" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Pre-Export Old Redis" {
  run run_hook "simple-single-old" "export-live" "$(payload default/export-live)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Update Old Redis Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/redis-cli set mykey date"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
}

@test "Stop Old Redis" {
  run run_hook "simple-single-old" "stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-old" bash -c "ps aux | grep [r]edis-server"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [r]edis-server"
  [ "$status" -eq 1 ] 
}

@test "Export Old Redis" {
  run run_hook "simple-single-old" "export-final" "$(payload default/export-final)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New SSHD" {
  # stop ssh server
  run run_hook "simple-single-new" "import-clean" "$(payload default/import-clean)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-new" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Restart New Redis" {
  run run_hook "simple-single-new" "start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [r]edis-server"
  [ "$status" -eq 0 ]
  until docker exec "simple-single-new" bash -c "nc 192.168.0.3 6379 < /dev/null"
  do
    sleep 1
  done
}

@test "Verify New Redis Data" {
  run docker exec "simple-single-new" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
}

@test "Stop Old Container" {
  stop_container "simple-single-old"
}

@test "Stop New Container" {
  stop_container "simple-single-new"
}