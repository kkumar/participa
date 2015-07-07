class SmsValidatorController < ApplicationController
  before_action :authenticate_user! 
  before_action :can_change_phone

  def can_change_phone
    unless current_user.can_change_phone?
      redirect_to root_path, flash: {error: "Ya has confirmado tu número en los últimos meses." }
    end
  end

  # GET /validator/step1
  def step1 
  end

  # GET /validator/step2
  def step2
    redirect_to sms_validator_step1_path if current_user.unconfirmed_phone.nil? 
    @user = current_user
  end

  # GET /validator/step3
  def step3
    if current_user.unconfirmed_phone.nil? 
      redirect_to sms_validator_step1_path 
      return
    end
    if current_user.sms_confirmation_token.nil? 
      redirect_to sms_validator_step2_path
      return
    end
    @user = current_user
    render action: "step3"
  end

  # POST /validator/phone
  def phone
    begin 
      phone = current_user.phone_normalize(phone_params[:unconfirmed_phone])
    rescue
      current_user.errors.add(:unconfirmed_phone, "Revisa el formato")
    end
    if phone.nil? 
      current_user.unconfirmed_phone = phone_params[:unconfirmed_phone]
    else
      current_user.unconfirmed_phone = phone
    end
    if current_user.save
      current_user.set_sms_token!
      redirect_to sms_validator_step2_path
    else
      render action: "step1"
    end
  end

  # POST /validator/captcha
  def captcha 
    if verify_recaptcha
      current_user.send_sms_token!
      render action: "step3"
    else
      flash.now[:error] = t('podemos.valid.phone.captcha_invalid') 
      render action: "step2"
    end
  end

  # POST /validator/valid
  def valid
    #if current_user.check_sms_token(params[:sms_token][:sms_user_token])
    if current_user.check_sms_token(sms_token_params[:sms_user_token_given])
      flash.now[:notice] = t('podemos.valid.phone.valid')

      if current_user.apply_previous_user_vote_location
        flash.now[:alert] = t('podemos.registration.message.existing_user_location')        
      end
      redirect_to authenticated_root_path
    else
      flash.now[:error] = t('podemos.valid.phone.invalid') 
      render action: "step3"
    end
  end

  private

  def phone_params
    params.require(:user).permit(:unconfirmed_phone)
  end

  def sms_token_params
    params.require(:user).permit(:sms_user_token_given)
  end

end
