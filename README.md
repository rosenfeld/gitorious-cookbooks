# Install procedures

For installing Gitorious in latest Debian stable using Opscode Chef for a completely automated process, follow these instructions:

    apt-get update
    echo "gem: --no-rdoc --no-ri" > /etc/gemrc
    apt-get install -y ruby ruby-dev libruby build-essential ssl-cert git
    cd /tmp
    wget http://production.cf.rubygems.org/rubygems/rubygems-1.5.2.tgz
    tar zxf rubygems-1.5.2.tgz
    ruby rubygems-1.5.2/setup.rb --no-format-executable
    gem install chef

    mkdir /etc/chef /root/chef-solo
    wget -O /etc/chef/solo.rb https://gist.github.com/raw/847256/chef-gitorious-etc-solo.rb
    mkdir /root/chef-solo
    wget -O /root/chef-solo/node.json https://gist.github.com/raw/847256/chef-gitorious-node-debian.json

First review the settings under /root/chef-solo/node.json and then procede with:

    cd /root/chef-solo
    git clone git://github.com/rosenfeld/gitorious-cookbooks.git cookbooks

    chef-solo

If you have any problems, please fill the issue [here](https://github.com/rosenfeld/gitorious-cookbooks/issues).
