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

@test "simple-single-environment" {
  run run_hook "simple-single" "environment" "$(payload environment)"

  [ "$status" -eq 0 ]

  [ "${lines[0]}" = "{" ]
  [ "${lines[1]}" = "  \"HOST\": \"192.168.0.2\"," ]
  [ "${lines[2]}" = "  \"PORT\": \"6379\"" ]
  [ "${lines[3]}" = "}" ]
}

@test "Stop Container" {
  stop_container "simple-single"
}