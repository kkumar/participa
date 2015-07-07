Rails.application.configure do

  # FIXME: AWS::SES::ResponseError: Throttling - Daily message quota exceeded.
  config.action_mailer.delivery_method = :ses
  #config.action_mailer.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {
    :address              => Rails.application.secrets.smtp["address"],
    :user_name            => Rails.application.secrets.smtp["user_name"],
    :password             => Rails.application.secrets.smtp["password"],
    :domain               => Rails.application.secrets.smtp["domain"],
    :port                 => 25,
    :authentication       => :login,
    :enable_starttls_auto => false
  }

end
