
service_name="Redis"
default_port=6379

wait_for_running() {
  container=$1
  until docker exec ${container} bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

wait_for_arbitrator_running() {
  container=$1
  until docker exec ${container} bash -c "ps aux | grep [r]edis-server | grep sentinel"
  do
    sleep 1
  done
}

wait_for_listening() {
  container=$1
  ip=$2
  port=$3
  run docker exec ${container} bash -c "if [ -f /etc/service/proxy/run ]; then sv restart proxy; fi;"
  until docker exec ${container} bash -c "nc -q 1 ${ip} ${port} < /dev/null"
  do
    sleep 1
  done
}

wait_for_stop() {
  container=$1
  while docker exec ${container} bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

verify_stopped() {
  container=$1
  run docker exec ${container} bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  echo_lines
  [ "$status" -eq 1 ] 
}

insert_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "if [ -f /etc/service/proxy/run ]; then sv restart proxy; fi;"
  sleep 5
  run docker exec ${container} bash -c "/data/bin/redis-cli set ${key} ${data}"
  [ "$status" -eq 0 ]
}

update_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "if [ -f /etc/service/proxy/run ]; then sv restart proxy; fi;"
  sleep 5
  run docker exec ${container} bash -c "/data/bin/redis-cli set ${key} ${data}"
  [ "$status" -eq 0 ]
}

verify_test_data() {
  container=$1
  ip=$2
  port=$3
  key=$4
  data=$5
  run docker exec ${container} bash -c "if [ -f /etc/service/proxy/run ]; then sv restart proxy; fi;"
  sleep 5
  run docker exec ${container} bash -c "/data/bin/redis-cli get ${key}"
  echo_lines
  [ "${lines[0]}" = "${data}" ]
  [ "$status" -eq 0 ]
}

verify_plan() {
  [ "${lines[0]}" = "{" ]
  [ "${lines[1]}" = "  \"redundant\": false," ]
  [ "${lines[2]}" = "  \"horizontal\": false," ]
  [ "${lines[3]}" = "  \"users\": [" ]
  [ "${lines[4]}" = "  ]," ]
  [ "${lines[5]}" = "  \"ips\": [" ]
  [ "${lines[6]}" = "    \"default\"" ]
  [ "${lines[7]}" = "  ]," ]
  [ "${lines[8]}" = "  \"port\": 6379," ]
  [ "${lines[9]}" = "  \"behaviors\": [" ]
  [ "${lines[10]}" = "    \"migratable\"," ]
  [ "${lines[11]}" = "    \"backupable\"" ]
  [ "${lines[12]}" = "  ]" ]
  [ "${lines[13]}" = "}" ]
}