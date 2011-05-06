package 'exim4'

template "/etc/exim4/update-exim4.conf.conf" do
  source 'update-exim4.conf.conf.erb'
  notifies :run, "execute[update-exim4.conf]"
end

cookbook_file "/etc/exim4/conf.d/auth/01_exim4-allow-notls-passwords" do
  source 'exim4.conf.localmacros'
  notifies :run, "execute[update-exim4.conf]"
end

template "/etc/exim4/passwd.client" do
  group  'Debian-exim'
  mode   '0640'
  source 'passwd.client.erb'
  notifies :run, "execute[update-exim4.conf]"
end

template("/etc/email-addresses") do
  mode   '0644'
  source 'email-addresses.erb'
end

service "exim4" do
  action      [ :enable, :start ]
  supports    :restart => true, :reload => true, :status => true
end

execute "update-exim4.conf" do
  command "/usr/sbin/update-exim4.conf" 
  action :nothing
  notifies :reload, "service[exim4]"
end
