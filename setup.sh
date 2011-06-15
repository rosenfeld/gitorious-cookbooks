#!/bin/sh
apt-get update
echo "gem: --no-rdoc --no-ri" > /etc/gemrc
apt-get install -y ruby ruby-dev libruby build-essential ssl-cert git
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.4.2.tgz
tar zxf rubygems-1.4.2.tgz
ruby rubygems-1.4.2/setup.rb --no-format-executable
gem install chef

mkdir /etc/chef /root/chef-solo
wget -O /etc/chef/solo.rb https://gist.github.com/raw/847256/chef-gitorious-etc-solo.rb
wget -O /root/chef-solo/node.json https://gist.github.com/raw/847256/chef-gitorious-node-debian.json
