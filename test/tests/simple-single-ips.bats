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
  start_container "simple-single" "192.168.0.2"
}

@test "IP Up" {
  run run_hook "simple-single" "ip-add" "$(payload ip-add)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify IP" {
  run docker exec simple-single bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 0 ] 
}

@test "IP Down" {
  run run_hook "simple-single" "ip-remove" "$(payload ip-remove)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify No IP" {
  run docker exec simple-single bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 1 ] 
}

@test "Stop Container" {
  stop_container "simple-single"
}