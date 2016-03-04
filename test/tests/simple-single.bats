# source docker helpers
. util/docker.sh

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
  run run_hook "simple-single-local" "default-configure" "$(payload default/configure-local)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Local Redis" {
  run run_hook "simple-single-local" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [r]edis-server"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-local" bash -c "nc 192.168.0.2 6379 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Local Redis Data" {
  run docker exec simple-single-local bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec simple-single-local bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Stop Local Redis" {
  run run_hook "simple-single-local" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-single-local" bash -c "ps aux | grep [r]edis-server"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-local bash -c "ps aux | grep [r]edis-server"
  echo_lines
  [ "$status" -eq 1 ] 
}

@test "Stop Local Container" {
  stop_container "simple-single-local"
}

@test "Start Production Container" {
  start_container "simple-single-production" "192.168.0.2"
}

@test "Configure Production Container" {
  run run_hook "simple-single-production" "default-configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ] 
}

@test "Start Production Redis" {
  run run_hook "simple-single-production" "default-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [r]edis-server"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-production" bash -c "nc 192.168.0.2 6379 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Production Redis Data" {
  run docker exec simple-single-production bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec simple-single-production bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Stop Production Redis" {
  run run_hook "simple-single-production" "default-stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
  while docker exec "simple-single-production" bash -c "ps aux | grep [r]edis-server"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-production bash -c "ps aux | grep [r]edis-server"
  echo_lines
  [ "$status" -eq 1 ] 
}

@test "Stop Production Container" {
  stop_container "simple-single-production"
}