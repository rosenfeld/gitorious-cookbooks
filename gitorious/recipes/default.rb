include_recipe "passenger_apache2::mod_rails"
apache_module "rewrite"
include_recipe "apache2::mod_ssl"

%w( libonig-dev libyaml-dev geoip-bin libgeoip-dev libgeoip1 imagemagick libmagickwand-dev libaspell-dev
    aspell mysql-server libmysqlclient-dev stompserver ssh apg sphinxsearch memcached ).each { |p| package p }

# comment the above line if you want to keep portmap and rpcbind
%w( portmap rpcbind ).each {|p| package(p) { action :purge } }

gem_package 'raspell'

gitorious_user  = 'git'
gitorious_user_home = "/home/#{gitorious_user}"
deploy_path = node[:gitorious][:deploy_path]
storage_dir = node[:gitorious][:storage_dir]

user(gitorious_user) { system true }

[gitorious_user_home, "#{gitorious_user_home}/.ssh"].each do |dir|
  directory dir do
    owner       gitorious_user
    group       gitorious_user
    mode        0700
  end
end

file(authorized_keys_path = "#{gitorious_user_home}/.ssh/authorized_keys") do
  owner       gitorious_user
  group       gitorious_user
  mode        0600
  action      :create
  not_if { File.exists? authorized_keys_path }
end

%w{ repositories tarballs tarballs-work }.each do |dir|
  directory "#{storage_dir}/#{dir}" do
    owner       gitorious_user
    group       gitorious_user
    mode        "2755"
    recursive   true
  end
end

execute "restart_gitorious_webapp" do
  command     %{touch #{deploy_path}/tmp/restart.txt}
  user        gitorious_user
  group       gitorious_user
  action      :nothing
end

directory deploy_path do
  owner       gitorious_user
  group       gitorious_user
  recursive   true
end

git deploy_path do
  repository  node[:gitorious][:git][:url]
  reference   node[:gitorious][:git][:reference]
  user        gitorious_user
  group       gitorious_user
  enable_submodules true
  action      :sync
  notifies    :run, "execute[restart_gitorious_webapp]"
end

directory "#{deploy_path}/tmp/pids" do
  owner       gitorious_user
  group       gitorious_user
  recursive   true
end

web_app "gitorious" do
  docroot "/var/www/gitorious/public"
  server_name node[:gitorious][:host]
  cookbook "passenger_apache2"
end

template "/etc/apache2/sites-available/gitorious-ssl" do
  source "gitorious-ssl.conf.erb"
  notifies :reload, "service[apache2]"
end
apache_site("default") { enable false }
apache_site "gitorious-ssl"

gem_package 'bundler'

execute "bundle --without development test" do
  cwd         deploy_path
  user        "root"
  group       "root"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

cookie_secret_filename = "#{deploy_path}/config/cookie_secret.txt"
execute(%Q{apg -m 64 | tr -d '"' | tr -d '\n' > #{cookie_secret_filename}}) { creates cookie_secret_filename }
ruby_block("fetch cookie secret") { block { node.set[:gitorious][:cookie_secret] = IO.read cookie_secret_filename } }

template "#{deploy_path}/config/gitorious.yml" do
  source      "gitorious.yml.erb"
  owner       gitorious_user
  group       gitorious_user
  mode        "0644"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

db_host     = node[:gitorious][:db][:host]
db_database = node[:gitorious][:db][:database]
db_user     = node[:gitorious][:db][:user]
db_password = node[:gitorious][:db][:password]

template "#{deploy_path}/config/database.yml" do
  source      "database.yml.erb"
  owner       gitorious_user
  group       gitorious_user
  mode        "0640"
  variables   :host => db_host, :database => db_database, :username => db_user, :password => db_password
  notifies    :run, "execute[restart_gitorious_webapp]"
end

script "create gitorious database" do
  interpreter "bash"
  cwd deploy_path
  code %Q{
    mysqladmin create #{db_database}
    mysql -e "GRANT ALL ON #{db_database}.* TO '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}';"
    export RAILS_ENV=production
    bundle exec rake db:setup
    echo -e "#{node[:gitorious][:admin][:email]}\\n#{node[:gitorious][:admin][:password]}" | script/create_admin
    chown -R git:git .
  }
  not_if "mysql -e 'show databases' | grep -q #{db_database}"
end

cookbook_file "#{deploy_path}/config/broker.yml" do
  source      "broker.yml"
  owner       gitorious_user
  group       gitorious_user
  mode        "0644"
  notifies    :run, "execute[restart_gitorious_webapp]"
end

script "setup ultrasphinx for Gitorious" do
  interpreter "bash"
  cwd         deploy_path
  code %Q{
    export RAILS_ENV=production
    bundle exec rake ultrasphinx:bootstrap

    aspell config dict-dir /usr/lib/aspell
    cp vendor/plugins/ultrasphinx/examples/ap.multi /usr/lib/aspell/
    bundle exec rake ultrasphinx:spelling:build

    chown git:git config/ultrasphinx/production.conf
  }
  creates     "#{deploy_path}/config/ultrasphinx/production.conf"
  notifies    :restart, "service[apache2]"
end

['ultrasphinx', 'daemon', 'poller'].each do |daemon|
  template "/etc/init.d/git-#{daemon}" do
    source      "git-#{daemon}.erb"
    mode        "0755"
    variables   :deploy_path => deploy_path
  end
end

cron "gitorious_ultrasphinx_reindexing" do
  user        gitorious_user
  command     "cd #{deploy_path} && bundle exec rake ultrasphinx:index RAILS_ENV=production 2>&1 >/dev/null"
end

service "git-ultrasphinx" do
  action      [ :enable, :start ]
  pattern     "searchd"
  supports    :restart => true, :reload => true, :status => false
end

service "git-daemon" do
  action      [ :enable, :start ]
  supports    :restart => true, :reload => false, :status => false
end

service "git-poller" do
  action      [ :enable, :start ]
  pattern     "poller"
  supports    :restart => true, :reload => true, :status => false
end

template "/etc/logrotate.d/gitorious" do
  source      "gitorious-logrotate.erb"
  owner       "root"
  group       "root"
  mode        "0644"
  variables   :deploy_path => deploy_path
end

template "/usr/local/bin/gitorious" do
  source      "gitorious.erb"
  mode        "0755"
  variables   :deploy_path => deploy_path
end
