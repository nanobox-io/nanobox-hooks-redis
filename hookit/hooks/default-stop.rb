if `sv status cache` =~ /^run/
  if File.exist?('/etc/service/proxy/run')
    execute "/data/bin/redis-cli -p 6380 shutdown save"
  else
    execute "/data/bin/redis-cli shutdown save"
  end
end

service "cache" do
  action :disable
  init :runit
end

service "sentinel" do
  action :disable
  only_if { File.exist?('/etc/service/sentinel/run') }
  init :runit
end

service "proxy" do
  action :disable
  only_if { File.exist?('/etc/service/proxy/run') }
  init :runit
end
