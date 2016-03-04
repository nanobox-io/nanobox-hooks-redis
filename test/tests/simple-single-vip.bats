# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Container" {
  start_container "simple-single" "192.168.0.2"
}

@test "Vip Up" {
  run run_hook "simple-single" "default-single-vip_up" "$(payload default/single/vip_up)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify Vip" {
  run docker exec simple-single bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 0 ] 
}

@test "Vip Down" {
  run run_hook "simple-single" "default-single-vip_down" "$(payload default/single/vip_down)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify No Vip" {
  run docker exec simple-single bash -c "ifconfig | grep 192.168.0.3"
  [ "$status" -eq 1 ] 
}

@test "Stop Container" {
  stop_container "simple-single"
}