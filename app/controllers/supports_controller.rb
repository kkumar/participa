class SupportsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    @proposal = Proposal.find(params[:proposal_id])
    unless @proposal.supported?(current_user)
      current_user.supports.create!(proposal: @proposal)
    end
  end

end