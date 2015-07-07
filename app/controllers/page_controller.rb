require 'securerandom'
class PageController < ApplicationController

  before_action :authenticate_user!, except: [:privacy_policy, :faq] 
  
  def privacy_policy
  end

  def faq
  end

end
