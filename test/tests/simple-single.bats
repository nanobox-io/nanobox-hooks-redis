# source docker helpers
. util/docker.sh
. util/service.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Production Container" {
  start_container "simple-single-production" "192.168.0.2"
}

@test "Configure Production Container" {
  run run_hook "simple-single-production" "configure" "$(payload configure)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Check To See That Extra Paths Were Set Up" {
  if [[ ! "$(grep extra_path_dirs ../src/configure)" =~ "extra_path_dirs" ]]; then
    skip "${service_name} Doesn't Support Extra Path Dirs"
  fi
  run docker exec "simple-single-production" cat /data/etc/env.d/EXTRA_PATHS
  echo_lines
  [ "$status" -eq 0 ]
  [ "${output}" = "/data/var/home/gonano/bin:/var/tmp" ]
}

@test "Check To See That Extra Packages Were Installed" {
  if [[ ! "$(grep extra_packages ../src/configure)" =~ "extra_packages" ]]; then
    skip "${service_name} Doesn't Support Extra Packages"
  fi
  run docker exec "simple-single-production" bash -c '[[ -f "/data/lib/libGeoIP.so" ]]'
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Check To See That Extra Steps Were Run" {
  if [[ ! "$(grep extra_steps ../src/configure)" =~ "extra_steps" ]]; then
    skip "${service_name} Doesn't Support Extra Steps"
  fi
  run docker exec "simple-single-production" bash -c '[[ -f "/tmp/extra_step" ]]'
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Check That Cron Jobs Are Created" {
  if [[ ! "$(grep cron_jobs ../src/configure)" =~ "cron_jobs" ]]; then
    skip "${service_name} Doesn't Support Cron"
  fi
  run docker exec "simple-single-production" bash -c '[[ -d "/opt/nanobox/cron" ]]'
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Production ${service_name}" {
  run run_hook "simple-single-production" "start" "$(payload start)"
  echo_lines
  [ "$status" -eq 0 ]
  # Verify
  wait_for_running "simple-single-production"
  wait_for_listening "simple-single-production" "192.168.0.2" ${default_port}
}

@test "Check That Cron Jobs Are Working" {
  if [[ ! "$(grep cron_jobs ../src/configure)" =~ "cron_jobs" ]]; then
    skip "${service_name} Doesn't Support Cron"
  fi
  # wait for cron jobs
  sleep 60
  run docker exec "simple-single-production" cat /tmp/test
  echo_lines
  [[ "$output" =~ "hi" ]]
}

@test "Insert Production ${service_name} Data" {
  insert_test_data "simple-single-production" "192.168.0.2" ${default_port} "mykey" "data"
  verify_test_data "simple-single-production" "192.168.0.2" ${default_port} "mykey" "data"
}

@test "Stop Production ${service_name}" {
  run run_hook "simple-single-production" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  run run_hook "simple-single-production" "stop" "$(payload stop)"
  echo_lines
  [ "$status" -eq 0 ]
  wait_for_stop "simple-single-production"
  # Verify
  verify_stopped "simple-single-production"
}

@test "Stop Production Container" {
  stop_container "simple-single-production"
}
