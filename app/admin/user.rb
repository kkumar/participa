ActiveAdmin.register User do
  config.per_page = 50

  scope_to User, association_method: :with_deleted

  scope :created, default: true
  scope :confirmed
  scope :deleted
  scope :unconfirmed_mail
  scope :unconfirmed_phone
  scope :legacy_password
  scope :confirmed_mail
  scope :confirmed_phone
  scope :signed_in
  scope :has_collaboration
  scope :has_collaboration_credit_card
  scope :has_collaboration_bank_national
  scope :has_collaboration_bank_international
  scope :participation_team
  scope :has_circle
  scope :banned
  scope :admins
  if Rails.application.secrets.features["verification_presencial"]
    scope :verifications_admin
    scope :verified_presencial
    scope :unverified_presencial
    scope :voting_right
  else
    scope :verified
  end

  permit_params :email, :district, :password, :password_confirmation, :first_name, :last_name, :document_type, :document_vatid, :born_at, :address, :town, :postal_code, :province, :country, :vote_province, :vote_town, :wants_newsletter

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :created_at
    column :verified_at
    column :district
    #column :verificated_users_count
    column :verified_by
    column :validations do |user|
      status_tag("Verificado", :ok) + br if user.is_verified?
      status_tag("Baneado", :error) + br if user.banned?
      user.confirmed_at? ? status_tag("Email", :ok) : status_tag("Email", :error)
      user.sms_confirmed_at? ? status_tag("Tel", :ok) : ""
      user.valid? ? status_tag("Val", :ok) : status_tag("Val", :error)
      user.deleted? ? status_tag("Borrado", :error) : ""
    end
    actions
  end

  show do
    authorize! :admin, user
    attributes_table do
      row :id
      row :status do
        if Rails.application.secrets.features["verification_presencial"]
          status_tag("Equipo de Verificación", :ok) if user.verifications_admin?
        end
        status_tag("Verificado", :ok) if user.is_verified?
        status_tag("Baneado", :error) if user.banned?
        user.deleted? ? status_tag("¡Atención! este usuario está borrado, no podrá iniciar sesión", :error) : ""
        if user.verified_by_id?
          status_tag("El usuario ha sido verificado de forma presencial", :ok)
        else
          status_tag("El usuario NO ha sido verificado de forma presencial", :error)
        end
        if user.confirmed_at?
          status_tag("El usuario ha confirmado por email", :ok)
        else
          status_tag("El usuario NO ha confirmado por email", :error)
        end
        if user.sms_confirmed_at?
          status_tag("El usuario ha confirmado por SMS", :ok)
        else
          status_tag("El usuario NO ha confirmado por SMS", :error)
        end
        if user.errors.any? # If there are errors, do something
          user.errors.each do |attribute, message|
            b attribute
            span message
          end
        end
      end
      row :esendex_status do
        if user.phone?
          span link_to("Ver en panel de Elementos Enviados de Esendex (confirmado)", "https://www.esendex.com/echo/a/#{Rails.application.secrets.esendex[:account_reference]}/Sent/Messages?FilterRecipientValue=#{user.phone.sub(/^00/,'')}")
        end
        if user.unconfirmed_phone? 
          span link_to("Ver en panel de Elementos Enviados de Esendex (no confirmado)", "https://www.esendex.com/echo/a/#{Rails.application.secrets.esendex[:account_reference]}/Sent/Messages?FilterRecipientValue=#{user.unconfirmed_phone.sub(/^00/,'')}")
        end
      end
      row :validations_status do
        if user.valid?
          status_tag("El usuario supera todas las validaciones", :ok)
        else
          status_tag("El usuario no supera alguna validación", :error)
          ul 
            user.errors.full_messages.each do |mes|
              li mes
            end
        end
      end
      row :full_name
      row :first_name
      row :last_name
      row :document_type do
        user.document_type_name
      end
      row :document_vatid
      row :born_at
      row :email
      row :vote_town_name
      row :address
      row :postal_code
      row :district
      
      row :country do
        user.country_name
      end
      row :autonomy do
        user.autonomy_name
      end
      row :province do
        user.province_name
      end
      row :town do
        user.town_name
      end
      row :in_spanish_island? do
        if user.in_spanish_island?
          user.island_name
        else
          status_tag("NO", :error)
        end
      end

      row :vote_place do
        user.vote_autonomy_name + " / " + user.vote_province_name + " / " + user.vote_town_name
      end
      row :vote_in_spanish_island? do
        if user.vote_in_spanish_island?
          user.vote_island_name
        else
          status_tag("NO", :error)
        end
      end

      row :admin
      row :circle
      row :created_at
      row :updated_at
      row :confirmation_sent_at
      row :confirmed_at
      row :unconfirmed_email
      row :has_legacy_password
      row "Teléfono móvil (confirmado)" do
        user.phone
      end
      row "Teléfono móvil (sin confirmar)" do
        user.unconfirmed_phone
      end
      row :sms_confirmation_token
      row :confirmation_sms_sent_at
      row :sms_confirmed_at
      #row :sms_confirmation do
      #  link_to "Ver en Esendex (proveedor SMS)", "https://www.esendex.com/echo/a//Sent/Messages?FilterRecipientValue="
      #end
      row :failed_attempts
      row :locked_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :last_sign_in_ip
      row :current_sign_in_ip
      row :remember_created_at
      row :deleted_at
      row :participation_team_at
      if Rails.application.secrets.features["verification_presencial"]
        row :verified_by
        row :verified_at
      end
    end

    panel "Votos" do
      if user.votes.any?
        table_for user.votes do
          column :election
          column :voter_id
          column :created_at
        end
      else
        "No hay votos asociados a este usuario."
      end
    end    

    if !user.participation_team_at.nil?

      panel "Equipos de Acción Participativa" do
        if user.participation_team.any?
          table_for user.participation_team do
            column :name
            column :active
          end
        else
          "El usuario no está inscrito en equipos específicos."
        end
      end
    end
    active_admin_comments
  end

  filter :email
  filter :document_vatid
  filter :first_name
  filter :last_name
  filter :phone
  filter :created_at
  filter :born_at
  filter :created_at
  filter :address
  filter :postal_code
  filter :current_sign_in_ip
  filter :last_sign_in_at
  filter :last_sign_in_ip
  filter :confirmed_at
  filter :verified_at
  filter :sms_confirmed_at
  filter :sign_in_count
  filter :district
  filter :votes_election_id, as: :select, collection: Election.all
  if defined? User.verifications_admin 
    filter :verified_by_id, as: :select, collection: User.verifications_admin.all
  end

  form partial: "form"

  csv do
    column :id
    column("Nombre") { |u| u.full_name }
    column :email
    column :document_vatid
    column :country_name
    column :province_name
    column :town_name
    column :address
    column :district
    column :postal_code
    column :country
    column :province
    column :town
    column :vote_town_name
    column :vote_town
    column :phone
    column :current_sign_in_ip
    column :last_sign_in_ip
    column :circle
  end

  action_item :only => :show do
    link_to('Recuperar usuario borrado', recover_admin_user_path(user), method: :post, data: { confirm: "¿Estas segura de querer recuperar este usuario?" }) if user.deleted?
  end

  action_item :only => :show do   
    if can? :ban, User
      if user.banned?
        link_to('Desbanear usuario', ban_admin_user_path(user), method: :delete) 
      else
        link_to('Banear usuario', ban_admin_user_path(user), method: :post, data: { confirm: "¿Estas segura de querer banear a este usuario?" }) 
      end
    end
  end

  action_item :only => :show do
    unless user.is_verified?
      msg = "¿Estas segura de querer verificar a este usuario?"
      if Rails.application.secrets.features["verification_presencial"]
        msg += " Recuerda revisar su documento y domicilio."
      end
      link_to('Verificar usuario', verify_admin_user_path(user), method: :post, data: { confirm: msg })
    end
  end

  if Rails.application.secrets.features["verification_presencial"]
    action_item :only => :show do
      if user.verifications_admin?
        link_to('Quitar de Equipo de Verificación', verification_unteam_admin_user_path(user), method: :post, data: { confirm: "¿Estas segura de querer que este usuario ya no verifique a otros?" })
      else
        link_to('Agregar a Equipo de Verificación', verification_team_admin_user_path(user), method: :post, data: { confirm: "¿Estas segura de querer que este usuario verifique a otros? Recuerda que debe ser una persona de confianza y que debes haber comprobado que haya firmado el documento legal." })
      end
    end
  end

  batch_action :ban, if: proc{ can? :ban, User } do |ids|
    User.ban_users(ids, true)
    redirect_to collection_path, alert: "Los usuarios han sido baneados."
  end

  member_action :ban, if: proc{ can? :ban, User }, :method => [:post, :delete] do
    User.ban_users([ params[:id] ], request.post?)
    flash[:notice] = "El usuario ha sido modificado"
    redirect_to action: :show
  end

  member_action :verify, :method => [:post] do
    u = User.find( params[:id] )
    if Rails.application.secrets.features["verification_presencial"]
      # use verified_at and verified_by fields
      u.verify! current_user
    else
      # use flags
      u.verified = true
      u.banned = false
      u.save
    end
    flash[:notice] = "El usuario ha sido modificado"
    redirect_to action: :show
  end

  if Rails.application.secrets.features["verification_presencial"]
    member_action :verification_team, :method => [:post] do
      u = User.find( params[:id] )
      u.verify! current_user
      u.verifications_admin = true
      u.save
      flash[:notice] = "El usuario ha sido modificado"
      redirect_to action: :show
    end

    member_action :verification_unteam, :method => [:post] do
      u = User.find( params[:id] )
      u.verifications_admin = false
      u.save
      flash[:notice] = "El usuario ha sido modificado"
      redirect_to action: :show
    end
  end

  member_action :recover, :method => :post do
    user = User.with_deleted.find(params[:id])
    user.restore
    flash[:notice] = "Ya se ha recuperado el usuario"
    redirect_to action: :show
  end

  sidebar :collaborations, only: :show do
    if user.collaboration
      attributes_table_for user.collaboration do
        row :link do
          link_to "Ver ficha", admin_collaboration_path(user.collaboration)
        end
        row :amount do |collaboration|
          number_to_currency ( collaboration.amount / 100.0 )
        end
        row :frequency_name
        row :payment_type_name
        row :created_at
      end
    else
      "No hay colaboraciones asociadas a este usuario."
    end
  end

  sidebar :versionate, :partial => "admin/version", :only => :show

  sidebar "Usuario verificados", only: :show do
    user = User.find( params[:id] )
    table_for user.verificated_users.each do 
      column "Usuarios verificados: #{user.verificated_users.count}" do |u|
        span link_to(u.full_name, admin_user_path(u))
        br
        span u.verified_at
      end
    end
  end

  sidebar "Control de IPs", only: :show do
    ips = [user.last_sign_in_ip, user.current_sign_in_ip]
    t = User.arel_table
    users = User.where.not(id:user.id).where(t[:last_sign_in_ip].in(ips).or(t[:current_sign_in_ip].in(ips)))
    table_for users.first(25) do
      column "Usuarios con la misma IP: #{users.count}" do |u|
        span link_to(u.full_name, admin_user_path(u))
        br
        span u.document_vatid
        span " - #{u.phone}" if u.phone
        br
        span b u.created_at.strftime "%Y-%m-%d %H:%M"
      end
    end
  end

  controller do
    def show
      @user = User.with_deleted.find(params[:id])
      @versions = @user.versions
      @user = @user.versions[params[:version].to_i].reify if params[:version]
      show! #it seems to need this
    end
  end

  sidebar "Equipos de participación", only: :index, priority: 0 do
    form action: download_participation_teams_admin_users_path, method: :post do
      input :name => :authenticity_token, :type => :hidden, :value => form_authenticity_token.to_s
      div class: :filter_form_field do
        label "Fecha de inicio"
        input name: :date, type: :date, placeholder:"dd/mm/aaaa", pattern:'\d{1,2}/\d{1,2}/\d{4}'
      end
      div class: :buttons do
        input :type => :submit, value: "Descargar"
      end
    end
  end

  collection_action :download_participation_teams, :method => :post do
    if params[:date].nil? or params[:date].empty?
      date = DateTime.civil(1900,1,1)
    else  
      date = DateTime.parse(params[:date])
    end

    csv = CSV.generate(encoding: 'utf-8', col_sep: "\t") do |csv|
      csv << ["ID", "Código de identificacion", "Nombre", "País", "Comunidad Autónoma", "Municipio", "Código postal", "Teléfono", "Círculo", "Email", "Equipos"]
      User.participation_team.where("participation_team_at>?", date).each do |user| 
        csv << [ user.id, "#{user.postal_code}#{user.phone}", user.first_name, user.country_name, user.autonomy_name, user.town_name, user.postal_code, user.phone, user.circle, user.email, user.participation_team.map { |team| team.name }.join(",") ]
      end
    end

    send_data csv.encode('utf-8'),
      type: 'text/tsv; charset=utf-8; header=present',
      disposition: "attachment; filename=podemos.participationteams.#{Date.today.to_s}.csv"
  end

  sidebar :report, only: :index do
    form action: create_report_admin_users_path, method: :post do
      input :name => :authenticity_token, :type => :hidden, :value => form_authenticity_token.to_s
      input :name => :query, :type => :hidden, :value => Report.serialize_relation_query(users)
      div class: :filter_form_field do
        label "Titulo"
        input name: :title
      end
      label "Grupos"
      div class: :filter_form_field do
        label "Principal"
        select name: :main_group do
          option value: nil do "-- Ninguno --" end
          ReportGroup.all.each do |g|
            option value: g.id do g.title end
          end
        end
      end
      div class: :filter_form_field do
        ReportGroup.all.each do |g|
          label do
            input name: "groups[]", type: :checkbox, value: g.id
            span g.title
          end
        end
      end
      div class: :buttons do
        input :type => :submit, value: "Crear informe"
      end
    end
  end

  collection_action :create_report, :method => :post do
    Report.create do |r|
      r.title = params[:title]
      r.query = params[:query]
      r.main_group = ReportGroup.find(params[:main_group].to_i).to_yaml if params[:main_group].to_i>0
      r.groups = ReportGroup.where(id: params[:groups].map {|g| g.to_i} ).to_yaml
    end
    flash[:notice] = "El informe ha sido generado"
    redirect_to action: :index
  end

end
