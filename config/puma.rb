bind 'unix:///var/run/puma.sock'
pidfile "/var/www/myblog/tmp/puma/pid"
state_path "/var/www/myblog/tmp/puma/state"
activate_control_app
