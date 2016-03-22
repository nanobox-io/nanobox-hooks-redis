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

@test "simple-single-plan" {
  run run_hook "simple-single" "plan" "$(payload plan)"
  echo_lines
  [ "$status" -eq 0 ]
  verify_plan
}

@test "Stop Container" {
  stop_container "simple-single"
}