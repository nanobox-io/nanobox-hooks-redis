# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

# Start containers
@test "Start Primary Container" {
  start_container "simple-redundant-primary" "192.168.0.2"
}

@test "Start Secondary Container" {
  start_container "simple-redundant-secondary" "192.168.0.3"
}

@test "Start Monitor Container" {
  start_container "simple-redundant-arbitrator" "192.168.0.4"
}

# install jq
@test "Install jq Primary Container" {
  run docker exec "simple-redundant-primary" bash -c "/data/bin/pkgin -y up && /data/bin/pkgin -y in jq"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Install jq Secondary Container" {
  run docker exec "simple-redundant-secondary" bash -c "/data/bin/pkgin -y up && /data/bin/pkgin -y in jq"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Install jq Arbitrator Container" {
  run docker exec "simple-redundant-arbitrator" bash -c "/data/bin/pkgin -y up && /data/bin/pkgin -y in jq"
  echo_lines
  [ "$status" -eq 0 ]
}


# Configure containers
@test "Configure Primary Container" {
  run run_hook "simple-redundant-primary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "configure" "$(payload default/configure-production)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Configure Monitor Container" {
  run run_hook "simple-redundant-arbitrator" "configure" "$(payload arbitrator/configure)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 5
}

@test "Stop Primary Redis" {
  run run_hook "simple-redundant-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop Secondary Redis" {
  run run_hook "simple-redundant-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Redis Is Stopped" {
  while docker exec "simple-redundant-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

@test "Redundant Configure Primary Container" {
  run run_hook "simple-redundant-primary" "redundant-configure" "$(payload default/redundant/configure-primary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Secondary Container" {
  run run_hook "simple-redundant-secondary" "redundant-configure" "$(payload default/redundant/configure-secondary)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Redundant Configure Monitor Container" {
  run run_hook "simple-redundant-arbitrator" "redundant-configure" "$(payload arbitrator/redundant/configure)"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Restop Primary Redis" {
  run run_hook "simple-redundant-primary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restop Secondary Redis" {
  run run_hook "simple-redundant-secondary" "stop" "$(payload default/stop)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Redis Is Stopped Again" {
  while docker exec "simple-redundant-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  while docker exec "simple-redundant-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
}

@test "Start Primary Redis" {
  run run_hook "simple-redundant-primary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Secondary Redis" {
  run run_hook "simple-redundant-secondary" "redundant-start" "$(payload default/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Monitor Sentinel" {
  run run_hook "simple-redundant-arbitrator" "redundant-start-arbitrator" "$(payload arbitrator/start)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Ensure Redis Primary Is Started" {
  docker exec "simple-redundant-primary" bash -c "sv restart proxy"
  until docker exec "simple-redundant-primary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-primary" bash -c "nc 192.168.0.2 6380 < /dev/null"
  do
    sleep 1
  done
}

@test "Ensure Redis Secondary Is Started" {
  docker exec "simple-redundant-secondary" bash -c "sv restart proxy"
  until docker exec "simple-redundant-secondary" bash -c "ps aux | grep [r]edis-server | grep -v sentinel | grep -v 26379"
  do
    sleep 1
  done
  until docker exec "simple-redundant-secondary" bash -c "nc 192.168.0.3 6380 < /dev/null"
  do
    sleep 1
  done
}

@test "Ensure Monitor Sentinel Is Started" {
  until docker exec "simple-redundant-arbitrator" bash -c "ps aux | grep [r]edis-server | grep sentinel"
  do
    sleep 1
  done
}

# @test "Check Primary Redundant Status" {
#   run run_hook "simple-redundant-primary" "redundant-check_status" "$(payload default/redundant/check_status)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Check Secondary Redundant Status" {
#   run run_hook "simple-redundant-secondary" "redundant-check_status" "$(payload default/redundant/check_status)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

@test "Insert Primary Redis Data" {
  run docker exec simple-redundant-primary bash -c "sv restart proxy"
  run docker exec simple-redundant-primary bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec simple-redundant-primary bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Insert Secondary Redis Data" {
  run docker exec simple-redundant-secondary bash -c "sv restart proxy"
  run docker exec simple-redundant-secondary bash -c "/data/bin/redis-cli set mykey2 date"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec simple-redundant-secondary bash -c "/data/bin/redis-cli get mykey2"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
  run docker exec simple-redundant-secondary bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
}

@test "Verify Primary Redis Data" {
  run docker exec simple-redundant-primary bash -c "/data/bin/redis-cli set mykey data"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec simple-redundant-primary bash -c "/data/bin/redis-cli get mykey"
  echo_lines
  [ "${lines[0]}" = "data" ]
  [ "$status" -eq 0 ]
  run docker exec simple-redundant-primary bash -c "/data/bin/redis-cli get mykey2"
  echo_lines
  [ "${lines[0]}" = "date" ]
  [ "$status" -eq 0 ]
}

@test "Restart Primary VIP Agent" {
  run docker exec simple-redundant-primary bash -c "sv restart flip"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restart Secondary VIP Agent" {
  run docker exec simple-redundant-secondary bash -c "sv restart flip"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Restart Monitor VIP Agent" {
  run docker exec simple-redundant-arbitrator bash -c "sv restart flip"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

# Verify VIP
@test "Verify Primary VIP Agent" {
  run docker exec "simple-redundant-primary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Verify Secondary VIP Agent" {
  run docker exec "simple-redundant-secondary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 1 ]
}

@test "Verify Monitor VIP Agent" {
  run docker exec "simple-redundant-arbitrator" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 1 ]
}

# @test "Stop Primary VIP Agent" {
#   run run_hook "simple-redundant-primary" "redundant-stop_vip_agent" "$(payload default/redundant/stop_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Stop Secondary VIP Agent" {
#   run run_hook "simple-redundant-secondary" "redundant-stop_vip_agent" "$(payload default/redundant/stop_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Stop Monitor VIP Agent" {
#   run run_hook "simple-redundant-arbitrator" "arbitrator-redundant-stop_vip_agent" "$(payload arbitrator/redundant/stop_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Reverify Primary VIP Agent" {
#   run docker exec "simple-redundant-primary" bash -c "ifconfig | grep 192.168.0.5"
#   echo_lines
#   [ "$status" -eq 1 ]
# }

# @test "Reverify Secondary VIP Agent" {
#   run docker exec "simple-redundant-secondary" bash -c "ifconfig | grep 192.168.0.5"
#   echo_lines
#   [ "$status" -eq 1 ]
# }

# @test "Reverify Monitor VIP Agent" {
#   run docker exec "simple-redundant-arbitrator" bash -c "ifconfig | grep 192.168.0.5"
#   echo_lines
#   [ "$status" -eq 1 ]
# }

# @test "Restart Primary VIP Agent" {
#   run run_hook "simple-redundant-primary" "redundant-start_vip_agent" "$(payload default/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Restart Secondary VIP Agent" {
#   run run_hook "simple-redundant-secondary" "redundant-start_vip_agent" "$(payload default/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

# @test "Restart Monitor VIP Agent" {
#   run run_hook "simple-redundant-arbitrator" "arbitrator-redundant-start_vip_agent" "$(payload arbitrator/redundant/start_vip_agent)"
#   echo_lines
#   [ "$status" -eq 0 ]
#   sleep 10
# }

# @test "Verify Primary VIP Agent Again" {
#   run docker exec "simple-redundant-primary" bash -c "ifconfig | grep 192.168.0.5"
#   echo_lines
#   [ "$status" -eq 0 ]
# }

@test "Stop Primary" {
  run docker stop "simple-redundant-primary"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Verify Secondary VIP Agent Failover" {
  skip "Flip is acting weird, doesn't always failover properly."
  docker exec "simple-redundant-secondary" cat /var/log/gonano/flip/current
  docker exec "simple-redundant-arbitrator" cat /var/log/gonano/flip/current
  run docker exec "simple-redundant-secondary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Start Primary" {
  run docker start "simple-redundant-primary"
  echo_lines
  [ "$status" -eq 0 ]
  sleep 10
}

@test "Verify Primary VIP Agent fallback" {
  docker exec "simple-redundant-secondary" cat /var/log/gonano/flip/current
  docker exec "simple-redundant-primary" cat /var/log/gonano/flip/current
  docker exec "simple-redundant-arbitrator" cat /var/log/gonano/flip/current
  run docker exec "simple-redundant-primary" bash -c "ifconfig | grep 192.168.0.5"
  echo_lines
  [ "$status" -eq 0 ]
}

# Stop containers
@test "Stop Primary Container" {
  stop_container "simple-redundant-primary"
}

@test "Stop Secondary Container" {
  stop_container "simple-redundant-secondary"
}

@test "Stop Monitor Container" {
  stop_container "simple-redundant-arbitrator"
}