# source docker helpers
. util/docker.sh

setup() {
	start_container "simple-single" "192.168.0.2"
}

teardown() {
	stop_container "simple-single"
}

@test "simple-single-configure-start" {
  run run_hook "simple-single" "default-configure" "$(payload simple-single)"

  run run_hook "simple-single" "default-start" "$(payload simple-single)"
  docker exec simple-single bash -c "cat /var/log/gonano/cache/current"
  docker exec simple-single bash -c "ls -lha /data/var/db/redis"
  docker exec simple-single bash -c "ls -lha /data/var/db"
  docker exec simple-single bash -c "ls -lha /data/var/"
  docker exec simple-single bash -c "ls -lha /data"
  docker exec simple-single bash -c "ls -lha /data/etc/redis.conf"
  docker exec simple-single bash -c "cat /data/etc/redis.conf"
  run docker exec simple-single bash -c "ps aux | grep [r]edis-server"
  echo "$output"
  [ "$status" -eq 0 ]
}