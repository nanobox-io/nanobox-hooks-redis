# source docker helpers
. util/docker.sh

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
  run run_hook "simple-redundant-old-primary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "configure" "$(payload arbitrator/configure)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

# Configure containers
@test "Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "configure" "$(payload arbitrator/configure)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Stop Old Redis" {
  run run_hook "simple-redundant-old-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New Redis" {
  run run_hook "simple-redundant-new-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Old Containers" {
  run run_hook "simple-redundant-old-primary" "redundant-configure" "$(payload default/redundant/configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-configure" "$(payload default/redundant/configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "redundant-configure" "$(payload arbitrator/redundant/configure)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Redundant Configure New Containers" {
  run run_hook "simple-redundant-new-primary" "redundant-configure" "$(payload default/redundant/configure-primary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-configure" "$(payload default/redundant/configure-secondary-new)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "redundant-configure" "$(payload arbitrator/redundant/configure-new)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Restop Old Redis" {
  run run_hook "simple-redundant-old-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restop New Redis" {
  run run_hook "simple-redundant-new-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Old Redis Are Stopped" {
  while docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

@test "Start Old Redis Cluster" {
  run run_hook "simple-redundant-old-primary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-arbitrator" "redundant-start-arbitrator" "$(payload arbitrator/start)"
  echo_lines
  [ "$status" -eq 0 ]
  docker exec "simple-redundant-old-primary" bash -c "sv restart proxy"
  docker exec "simple-redundant-old-secondary" bash -c "sv restart proxy"
  until docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-primary" bash -c "nc 192.168.0.2 6379 < /dev/null"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-secondary" bash -c "nc 192.168.0.3 6379 < /dev/null"
  do
    sleep 1
  done
  until docker exec "simple-redundant-old-arbitrator" bash -c "ps aux | grep [r]edis-server | grep sentinel"
  do
    sleep 1
  done
}

@test "Ensure New Redis Are Stopped" {
  while docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-primary" bash -c "nc 192.168.0.6 6379 < /dev/null"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-secondary" bash -c "nc 192.168.0.7 6379 < /dev/null"
  do
    sleep 1
  done
}

@test "Start New SSHD" {
  # start ssh server
  run run_hook "simple-redundant-new-primary" "redundant-import-prep" "$(payload default/redundant/import-prep)"
  echo_lines
  [ "$status" -eq 0 ]
  # start ssh server
  run run_hook "simple-redundant-new-secondary" "redundant-import-prep" "$(payload default/redundant/import-prep)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Insert Old Redis Data" {
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Redundant Old Pre-Export" {
  run run_hook "simple-redundant-old-primary" "redundant-export-live" "$(payload default/redundant/export-live)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Insert Old Redis Data" {
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/redis-cli set mykey2 date"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-old-primary" bash -c "/data/bin/redis-cli get mykey2"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
}

@test "Restop Old Redis" {
  run run_hook "simple-redundant-old-primary" "redundant-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-old-secondary" "redundant-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Old Redis Are Stopped" {
  while docker exec "simple-redundant-old-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-old-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

@test "Redundant Old Export" {
  run run_hook "simple-redundant-old-primary" "redundant-export-final" "$(payload default/redundant/export-final)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New SSHD" {
  # stop ssh server
  run run_hook "simple-redundant-new-primary" "redundant-import-clean" "$(payload default/redundant/import-clean)"
  echo_lines
  [ "$status" -eq 0 ]
  # stop ssh server
  run run_hook "simple-redundant-new-secondary" "redundant-import-clean" "$(payload default/redundant/import-clean)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
  while docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}
@test "Start New Redis Cluster" {
  run run_hook "simple-redundant-new-primary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-secondary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-redundant-new-arbitrator" "redundant-start-arbitrator" "$(payload arbitrator/start)"
  echo_lines
  [ "$status" -eq 0 ]
  docker exec "simple-redundant-new-primary" bash -c "sv restart proxy"
  docker exec "simple-redundant-new-secondary" bash -c "sv restart proxy"
  until docker exec "simple-redundant-new-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-primary" bash -c "nc 192.168.0.6 6379 < /dev/null"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-secondary" bash -c "nc 192.168.0.7 6379 < /dev/null"
  do
    sleep 1
  done
  until docker exec "simple-redundant-new-arbitrator" bash -c "ps aux | grep [r]edis-server | grep sentinel"
  do
    sleep 1
  done
}

@test "Verify New Primary Redis Data" {
  skip
  run docker exec "simple-redundant-new-primary" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-new-primary" bash -c "/data/bin/redis-cli get mykey2"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
}

@test "Verify New Secondary Redis Data" {
  skip
  run docker exec "simple-redundant-new-secondary" bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
  run docker exec "simple-redundant-new-secondary" bash -c "/data/bin/redis-cli get mykey2"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
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