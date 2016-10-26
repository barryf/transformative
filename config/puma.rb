app = "transformative"

root = "#{Dir.getwd}/.."

bind "unix://#{root}/tmp/#{app}.sock"
pidfile "#{root}/tmp/#{app}.pid"
state_path "#{root}/tmp/#{app}.state"
rackup "#{root}/#{app}/config.ru"

threads 4, 8

activate_control_app
