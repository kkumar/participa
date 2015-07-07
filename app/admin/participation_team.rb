ActiveAdmin.register ParticipationTeam do

  if Rails.application.secrets.features["participation_teams"]
    menu :parent => "Users"
  else 
    menu false
  end

  permit_params :name, :description, :active

  filter :name
  filter :active
  filter :created_at

end
