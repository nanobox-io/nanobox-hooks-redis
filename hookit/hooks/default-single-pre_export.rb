
# find available space
new_member_stat = `ssh -o StrictHostKeyChecking=no #{payload[:new_member][:local_ip]} stat -f --format=\\\"%a %S\\\" /data/var/db/mysql`
available_space = new_member_stat.split(' ')[0].to_i * new_member_stat.split(' ')[1].to_i

# find needed space
needed_space = `du -bs /data/var/db/mysql`.split(' ')[0].to_i

if available_space < needed_space
  puts "Receiving side too small!!"
  exit 1
end #unless payload[:clear_data] == "false"


# issue save to the local redis
# 'save' rather than 'bgsave' so it blocks
execute 'execute save' do
  command '/data/bin/redis-cli save'
end

execute "send bulk data to new member" do
  command "tar -cf - /data/var/db/redis | ssh -o StrictHostKeyChecking=no #{payload[:new_member][:local_ip]} tar -xpf -"
end
