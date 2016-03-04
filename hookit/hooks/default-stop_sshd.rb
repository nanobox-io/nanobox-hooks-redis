
service 'ssh' do
  action :disable
  init :runit
end

directory '/etc/service/ssh' do
  action :delete
end