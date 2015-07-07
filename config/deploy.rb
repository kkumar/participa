lock '3.2.1'

set :application, 'participa'
repo_url = 'git@git.alabs.org:alabs/participa.git'
set :repo_url, repo_url
set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system db/podemos}
