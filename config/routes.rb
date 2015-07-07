require 'dynamic_router'
Rails.application.routes.draw do
  # FIXME: routes always on spanish, redirect the legacy (english) routes

  get '', to: redirect("/#{I18n.locale}")

  # redsys MerchantURL 
  post '/orders/callback/redsys', to: 'orders#callback_redsys', as: 'orders_callback_redsys'

  namespace :api do
    scope :v1 do 
      scope :gcm do 
        post 'registrars', to: 'v1#gcm_registrate'
        delete 'registrars/:registrar_id', to: 'v1#gcm_unregister'
      end
      scope :user do
        get 'exists', to: 'v1#user_exists'
      end
    end
  end

  get '/favicon.ico', to: "organization#favicon"

  scope "/(:locale)", locale: /es|ca|eu/ do 

    devise_for :users, controllers: { 
      registrations: 'registrations', 
      passwords:     'passwords', 
      confirmations: 'confirmations'
    } 

    get '/privacy-policy', to: 'page#privacy_policy', as: 'page_privacy_policy'
    get '/preguntas-frecuentes', to: 'page#faq', as: 'faq'

    if Rails.application.secrets.features["notifications"]
      get :notices, to: 'notice#index', as: 'notices'
    end

    if Rails.application.secrets.features["openid"]
      get '/openid/discover', to: 'open_id#discover', as: "open_id_discover"
      get '/openid', to: 'open_id#index', as: "open_id_index"
      post '/openid', to: 'open_id#create', as: "open_id_create"
      get '/user/:id', to: 'open_id#user', as: "open_id_user"
      get '/user/xrds', to: 'open_id#xrds', as: "open_id_xrds"
    end

    if Rails.application.secrets.features["participation_teams"]
      get '/equipos-de-accion-participativa', to: 'participation_teams#index', as: 'participation_teams'
      put '/equipos-de-accion-participativa/entrar(/:team_id)', to: 'participation_teams#join', as: 'participation_teams_join'
      put '/equipos-de-accion-participativa/dejar(/:team_id)', to: 'participation_teams#leave', as: 'participation_teams_leave'
      patch '/equipos-de-accion-participativa/actualizar', to: 'participation_teams#update_user', as: 'participation_teams_update_user'
    end

    if Rails.application.secrets.features["proposals"]
      get '/propuestas', to: 'proposals#index', as: 'proposals'
      get '/propuestas/info', to: 'proposals#info', as: 'proposals_info'
      get '/propuestas/:id', to: 'proposals#show', as: 'proposal'
      post '/apoyar/:proposal_id', to: 'supports#create', as: 'proposal_supports'
    end

    if Rails.application.secrets.features["elections"]
      get '/vote/create/:election_id', to: 'vote#create', as: :create_vote
      get '/vote/create_token/:election_id', to: 'vote#create_token', as: :create_token_vote
      get '/vote/check/:election_id', to: 'vote#check', as: :check_vote
    end

    if Rails.application.secrets.features["verification_presencial"]
      scope '/verificadores' do 
        get '/', to: 'verification#step1', as: :verification_step1
        get '/nueva', to: 'verification#step2', as: :verification_step2
        get '/confirmar', to: 'verification#step3', as: :verification_step3
        post '/search', to: 'verification#search', as: :verification_search
        post '/confirm', to: 'verification#confirm', as: :verification_confirm
        get '/ok', to: 'verification#result_ok', as: :verification_result_ok
        get '/ko', to: 'verification#result_ko', as: :verification_result_ko
      end
      scope '/verificaciones' do 
        get '/', to: 'verification#show', as: :verification_show
      end
    end
    
    if Rails.application.secrets.features["microcredits"]
      get '/microcreditos', to: 'microcredit#index', as: 'microcredit'
      get '/microcréditos', to: redirect('/microcreditos')
      get '/microcreditos/provincias', to: 'microcredit#provinces'
      get '/microcreditos/municipios', to: 'microcredit#towns'
      get '/microcreditos/informacion', to: 'microcredit#info', as: 'microcredits_info'
      get '/microcreditos/:id', to: 'microcredit#new_loan', as: :new_microcredit_loan
      get '/microcreditos/:id/login', to: 'microcredit#login', as: :microcredit_login
      post '/microcreditos/:id', to: 'microcredit#create_loan', as: :create_microcredit_loan
    end
    
    authenticate :user do

      if Rails.application.secrets.features["verification_sms"]
        scope :validator do
          scope :sms do 
            get :step1, to: 'sms_validator#step1', as: 'sms_validator_step1'
            get :step2, to: 'sms_validator#step2', as: 'sms_validator_step2'
            get :step3, to: 'sms_validator#step3', as: 'sms_validator_step3'
            post :phone, to: 'sms_validator#phone', as: 'sms_validator_phone'
            post :captcha, to: 'sms_validator#captcha', as: 'sms_validator_captcha'
            post :valid, to: 'sms_validator#valid', as: 'sms_validator_valid'
          end
        end
      end
      
      if Rails.application.secrets.features["collaborations"]
        scope :colabora do
          delete 'baja', to: 'collaborations#destroy', as: 'destroy_collaboration'
          get 'ver', to: 'collaborations#edit', as: 'edit_collaboration'
          get '', to: 'collaborations#new', as: 'new_collaboration'
          get 'confirmar', to: 'collaborations#confirm', as: 'confirm_collaboration'
          post 'crear', to: 'collaborations#create', as: 'create_collaboration'
          post 'modificar', to: 'collaborations#modify', as: 'modify_collaboration'
          get 'OK', to: 'collaborations#OK', as: 'ok_collaboration'
          get 'KO', to: 'collaborations#KO', as: 'ko_collaboration'
        end
      end

      if Rails.application.secrets.features["blog"]
        scope :brujula do
          get '', to: 'blog#index', as: 'blog'
          get ':id', to: 'blog#post', as: 'post'
          get 'categoria/:id', to: 'blog#category', as: 'category'
        end
      end
    end

    # http://stackoverflow.com/a/8884605/319241 
    devise_scope :user do
      get '/registrations/regions/provinces', to: 'registrations#regions_provinces'
      get '/registrations/regions/municipies', to: 'registrations#regions_municipies'
      get '/registrations/vote/municipies', to: 'registrations#vote_municipies'

      authenticated :user do
        root 'tools#index', as: :authenticated_root
        get 'password/new', to: 'legacy_password#new', as: 'new_legacy_password'
        post 'password/update', to: 'legacy_password#update', as: 'update_legacy_password'
        delete 'password/recover', to: 'registrations#recover_and_logout'
      end
      unauthenticated do
        root 'devise/sessions#new', as: :root
      end
    end

    %w(404 422 500).each do |code|
      get code, to: 'errors#show', code: code
    end

    DynamicRouter.load
  end
  # /admin
  ActiveAdmin.routes(self)

  constraints CanAccessResque.new do
    mount Resque::Server.new, at: '/admin/resque', as: :resque
  end

  load "./vendor/overrides/#{Rails.application.secrets.organization["folder"]}/config/routes.rb"

end
