deploy_prod_server = 'participa.barcelonaencomu.cat'
deploy_prod_to = '/srv/rails/participa.barcelonaencomu.cat'

role [ :app, :db, :web ], [ deploy_prod_server ]

set :branch, :production
set :deploy_to, deploy_prod_to

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :start do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production start"
      #execute "sudo /etc/init.d/god start"
    end
  end
  task :stop do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production stop"
      #execute "sudo /etc/init.d/god stop"
    end
  end
  task :restart do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production restart"
      #execute "sudo /etc/init.d/god restart"
    end
  end
end
