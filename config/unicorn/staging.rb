directory = "/var/www/beta.participa.zaragozaencomun.com"
socket = "/tmp/unicorn.beta.participa.zaragozaencomun.com.sock"

working_directory "#{directory}/current"
pid "#{directory}/current/tmp/pids/unicorn.pid"
stderr_path "#{directory}/shared/log/unicorn.log"
stdout_path "#{directory}/shared/log/unicorn.log"
listen socket
worker_processes 4
timeout 120
