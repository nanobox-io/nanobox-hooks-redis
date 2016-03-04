include Hooky::Redis

boxfile = converge( Hooky::Redis::BOXFILE_DEFAULTS, payload[:boxfile] )

directory '/data/var/db/redis' do
  recursive true
end

if payload[:platform] == 'local'
  maxmemory = 128
  appname   = 'nanobox'
else
  total_mem = `vmstat -s | grep 'total memory' | awk '{print $1}'`.to_i
  cgroup_mem = `cat /sys/fs/cgroup/memory/memory.limit_in_bytes`.to_i
  maxmemory = [ total_mem / 1024, cgroup_mem / 1024 / 1024 ].min
  appname   = 'nanobox'
end

# chown data/var/db/redis for gonano
execute 'chown /data/var/db/redis' do
  command 'chown -R gonano:gonano /data/var/db/redis'
end

# Import service (and start)
directory '/etc/service/cache' do
  recursive true
end

directory '/etc/service/cache/log' do
  recursive true
end

directory '/data/etc/redis' do
  recursive true
end

# Configure redis
template '/data/etc/redis/redis.conf' do
  mode 0755
  source 'redis.conf.erb'
  variables ({ boxfile: boxfile, maxmemory: maxmemory })
end

template '/etc/service/cache/log/run' do
  mode 0755
  source 'log-run.erb'
  variables ({ svc: "cache" })
end

template '/etc/service/cache/run' do
  mode 0755
  variables ({ exec: "redis-server /data/etc/redis/redis.conf 2>&1" })
end

# Configure narc
template '/opt/gonano/etc/narc.conf' do
  variables ({ uid: payload[:uid], app: appname, logtap: payload[:logtap_host] })
end

directory '/etc/service/narc'

file '/etc/service/narc/run' do
  mode 0755
  content <<-EOF
#!/bin/sh -e
export PATH="/opt/local/sbin:/opt/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/gonano/sbin:/opt/gonano/bin"

exec /opt/gonano/bin/narcd /opt/gonano/etc/narc.conf
  EOF
end

if payload[:platform] != 'local'

  # Setup root keys for data migrations
  directory '/root/.ssh' do
    recursive true
  end

  file '/root/.ssh/id_rsa' do
    content payload[:ssh][:admin_key][:private_key]
    mode 0600
  end

  file '/root/.ssh/id_rsa.pub' do
    content payload[:ssh][:admin_key][:public_key]
  end

  file '/root/.ssh/authorized_keys' do
    content payload[:ssh][:admin_key][:public_key]
  end

  # Create some ssh host keys
  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_rsa_key -N '' -t rsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_rsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_dsa_key -N '' -t dsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_dsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_ecdsa_key' }
  end

  execute "ssh-keygen -f /opt/gonano/etc/ssh/ssh_host_ed25519_key -N '' -t ed25519" do
    not_if { ::File.exists? '/opt/gonano/etc/ssh/ssh_host_ed25519_key' }
  end

end
