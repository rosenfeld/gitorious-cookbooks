# Install procedures

For installing Gitorious in latest Debian stable using Opscode Chef for a completely automated process, follow these instructions:

    wget -qO- https://raw.github.com/rosenfeld/gitorious-cookbooks/master/setup.sh | sh

First review the settings under /root/chef-solo/node.json. TODO: currently GMail is not supported as smtp relay server. Then procede with:

    cd /root/chef-solo
    chef-solo

# Troubleshoot

If you have any problems, please fill the issue [here](https://github.com/rosenfeld/gitorious-cookbooks/issues).

If for some reason apache is not listening in port 443 after install, please restart apache manually:

    invoke-rc.d apache2 restart

I have no idea why this happened to me once...
