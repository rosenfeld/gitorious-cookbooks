package "bash-completion"

cookbook_file("/etc/profile.d/bash-config.sh") do
  source "bashrc"
  mode "0644"
end
