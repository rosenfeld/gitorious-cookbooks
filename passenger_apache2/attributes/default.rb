default[:passenger][:version]                           = "3.0.7"
    set[:passenger][:root_path]                         = "#{languages[:ruby][:gems_dir]}/gems/passenger-#{passenger[:version]}"
    set[:passenger][:module_path]                       = "#{passenger[:root_path]}/ext/apache2/mod_passenger.so"
default[:passenger][:max_pool_size]                     = 2
default[:passenger][:pool_idle_time]                    = 0
default[:passenger][:rails_app_spawner_idle_time]       = 0
default[:passenger][:rails_framework_spawner_idle_time] = 0

