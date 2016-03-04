
# issue save to the local redis
# 'save' rather than 'bgsave' so it blocks
if File.exist?('/etc/service/proxy/run')
  execute "/data/bin/redis-cli -p 6380 save"
else
  execute "/data/bin/redis-cli save"
end

# TODO: assuming we can scp backups to a backup container
execute "send data to backup container" do
  command <<-EOF
    bash -c 'gzip -c /data/var/db/redis/dump.rdb \
      | tee >(md5sum | cut -f1 -d" " > /tmp/md5sum) \
      | ssh \
      -o StrictHostKeyChecking=no \
      #{payload[:backup][:local_ip]} \
      "cat > /data/var/db/redis/#{payload[:backup][:backup_id]}.gz"
    for i in ${PIPESTATUS[@]}; do
      if [[ $i -ne 0 ]]; then
        exit $i
      fi
    done
    '
  EOF
end

remote_sum = `ssh -o StrictHostKeyChecking=no #{payload[:backup][:local_ip]} "md5sum /data/var/db/redis/#{payload[:backup][:backup_id]}.gz"`.to_s.strip.split(' ').first

# Read POST results
local_sum = File.open('/tmp/md5sum') {|f| f.readline}.strip

# Ensure checksum match
if remote_sum != local_sum
  puts 'checksum mismatch'
  exit 1
end
