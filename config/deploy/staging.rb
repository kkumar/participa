deploy_stag_server = 'participa.barcelonaencomu.cat'
deploy_stag_to = '/srv/rails/betaparticipa2.barcelonaencomu.cat'

role [ :app, :db, :web ], [ deploy_stag_server ]

set :branch, :staging
set :deploy_to, deploy_stag_to

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :start do
    on roles(:app) do
      execute "/etc/init.d/unicorn_staging start"
      #execute "sudo /etc/init.d/god start"
    end
  end
  task :stop do
    on roles(:app) do
      execute "/etc/init.d/unicorn_staging stop"
      #execute "sudo /etc/init.d/god stop"
    end
  end
  task :restart do
    on roles(:app) do
      execute "/etc/init.d/unicorn_staging restart"
      #execute "sudo /etc/init.d/god restart"
    end
  end
end
