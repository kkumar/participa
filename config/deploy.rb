lock '3.2.1'

set :application, 'participa'
set :repo_url, "git@github.com:ZaragozaEnComun/participa.git"
set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system db/podemos}
