
# Import service (and start)
directory '/etc/service/ssh' do
  recursive true
end

directory '/etc/service/ssh/log' do
  recursive true
end

template '/etc/service/ssh/log/run' do
  mode 0755
  source 'log-run.erb'
  variables ({ svc: "ssh" })
end

template '/etc/service/ssh/run' do
  mode 0755
  source 'run-root.erb'
  variables ({ exec: "/opt/gonano/sbin/sshd -D -e 2>&1" })
end

service 'ssh' do
  action :enable
  init :runit
end

ensure_socket 'ssh' do
  port '22'
  action :listening
end
