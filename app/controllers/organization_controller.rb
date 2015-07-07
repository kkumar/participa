class OrganizationController < ApplicationController

  def favicon
    send_file "#{Rails.root}/vendor/overrides/#{Rails.application.secrets.organization["folder"]}/public/favicon.ico"
  end

end
