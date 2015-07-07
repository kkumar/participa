class Ability
  include CanCan::Ability

  def initialize(user)
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    user ||= User.new # guest user (not logged in)
    if user.is_admin?
      can :manage, :all
      can :manage, Notice
      can :manage, Resque
      can :manage, Report
      can :manage, ActiveAdmin
      can :admin, User
      can :admin, Microcredit
      can :admin, MicrocreditLoan
      can :manage, Post

      if !user.superadmin?
        cannot :manage, Election
        cannot :manage, Notice
        cannot :manage, ReportGroup
        cannot :manage, SpamFilter
        can :read, Election
      end

    else
      cannot :manage, :all
      cannot :manage, Resque
      cannot :manage, ActiveAdmin

      can [:read], MicrocreditLoan if user.microcredits_admin?
      can [:read, :update], Microcredit if user.microcredits_admin?

      if Rails.application.secrets.features["verification_presencial"] 
        can [:step1, :step2, :step3, :confirm, :search, :result_ok, :result_ko], :verification if user.verifications_admin?
        can [:create, :create_token, :check], :vote if user.is_verified?
        can :show, :verification
      else
        can [:create, :create_token, :check], :vote if user.sms_confirmed_at?
      end

      can [:show, :update], User, id: user.id
      can :show, Notice
      can :read, Post.published

      cannot :admin, :all
    end

  end
end
