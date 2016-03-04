
execute "retrieve data from backup container" do
  command <<-EOF
    ssh -o StrictHostKeyChecking=no #{payload[:backup][:local_ip]} \
    'cat /data/var/db/redis/#{payload[:backup][:backup_id]}.gz' \
      | gunzip \
      > /dump.rdb.tmp
  EOF
end

# forced 'appendonly no'
execute 'clean data dir from failed saves' do
  command 'rm -rf /data/var/db/redis/temp*.rdb'
end

execute 'flush redis' do
  command '/data/bin/redis-cli flushall'
end

# TODO: requires `pip install rdbtools`
execute 'replay dump to redis' do
  command '/data/bin/rdb --command protocol /dump.rdb.tmp | /data/bin/redis-cli --pipe'
end

execute 'cleanup dump' do
  command 'rm -f /dump.rdb.tmp'
end

