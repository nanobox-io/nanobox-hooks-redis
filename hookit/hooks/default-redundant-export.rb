
payload[:generation][:members].each do |member|

  if member[:type] == 'default'

    execute "send diff data to new member" do
      command "rsync --delete -a /data/var/db/redis/. #{member[:local_ip]}:/data/var/db/redis/"
    end

  end
end
