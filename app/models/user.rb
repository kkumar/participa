class User < ActiveRecord::Base
  include FlagShihTzu

  include Rails.application.routes.url_helpers
  require 'phone'

  has_flags 1 => :banned,
            2 => :superadmin,
            3 => :verified,
            4 => :microcredits_admin,
            5 => :verifications_admin

  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  before_update :_clear_caches
  before_save :before_save

  acts_as_paranoid
  has_paper_trail

  has_many :votes, dependent: :destroy
  has_many :supports, dependent: :destroy
  has_one :collaboration, dependent: :destroy
  has_and_belongs_to_many :participation_team
  has_many :microcredit_loans
  belongs_to :verified_by, class_name: "User", foreign_key: "verified_by_id" #, counter_cache: :verified_by_id
  has_many :verificated_users, class_name: "User", foreign_key: "verified_by_id"

  validates :first_name, :last_name, :document_type, :document_vatid, presence: true
  validates :address, :postal_code, :town, :province, :country, :born_at, presence: true
  validates :email, confirmation: true, on: :create, :email => true
  validates :email_confirmation, presence: true, on: :create
  validates :terms_of_service, acceptance: true
  validates :over_18, acceptance: true
  validates :document_type, inclusion: { in: [1, 2, 3], message: "Tipo de documento no válido" }
  validates :document_vatid, valid_nif: true, if: :is_document_dni?
  validates :document_vatid, valid_nie: true, if: :is_document_nie?
  validates :born_at, date: true, allow_blank: true # gem date_validator
  validates :phone, numericality: true, allow_blank: true
  validates :unconfirmed_phone, numericality: true, allow_blank: true

  validates :email, uniqueness: {case_sensitive: false, scope: :deleted_at }
  validates :document_vatid, uniqueness: {case_sensitive: false, scope: :deleted_at }
  validates :phone, uniqueness: {scope: :deleted_at}, allow_blank: true, allow_nil: true
  validates :unconfirmed_phone, uniqueness: {scope: :deleted_at}, allow_blank: true, allow_nil: true

  validate :validates_postal_code
  validate :validates_phone_format
  validate :validates_unconfirmed_phone_format
  validate :validates_unconfirmed_phone_uniqueness

  def validates_postal_code
    if self.country == "ES"
      if (self.postal_code =~ /^\d{5}$/) != 0
        self.errors.add(:postal_code, "El código postal debe ser un número de 5 cifras")
      else
        province = Carmen::Country.coded("ES").subregions.coded(self.province)
        if province and self.postal_code[0...2] != province.subregions[0].code[2...4]
          self.errors.add(:postal_code, "El código postal no coincide con la provincia indicada")
        end
      end
    end
  end

  def validates_unconfirmed_phone_uniqueness
    if self.unconfirmed_phone.present?
      if User.confirmed_phone.where(phone: self.unconfirmed_phone).exists?
        self.errors.add(:phone, "Ya hay alguien con ese número de teléfono")
      end
    end
  end

  def validates_phone_format
    if self.phone.present?
      self.errors.add(:phone, "Revisa el formato de tu teléfono") unless Phoner::Phone.valid?(self.phone)
    end
  end

  def validates_unconfirmed_phone_format
    if self.unconfirmed_phone.present?
      self.errors.add(:unconfirmed_phone, "Revisa el formato de tu teléfono") unless Phoner::Phone.valid?(self.unconfirmed_phone)
      if self.country.downcase == "es" and not (self.unconfirmed_phone.starts_with?('00346') or self.unconfirmed_phone.starts_with?('00347'))
        self.errors.add(:unconfirmed_phone, "Debes poner un teléfono móvil válido de España empezando por 6 o 7.")
      end
    end
  end

  def check_issue(validation_response, path, message, controller)
    if validation_response
      if message and validation_response.class == String
          message[message.first[0]] = validation_response
      end
      return {path: path, message: message, controller: controller}
    end
  end

  # returns issues with user profile, blocking first
  def get_unresolved_issue(only_blocking = false)

    # User have a valid born date
    issue ||= check_issue (self.born_at.nil? || (self.born_at == Date.civil(1900,1,1))), :edit_user_registration, { alert: "born_at"}, "registrations"

    # User must review his location (town code first letter uppercase)
    issue ||= check_issue self.town.starts_with?("M_"), :edit_user_registration, { notice: "location"}, "registrations"

    # User have a valid location
    issue ||= check_issue self.verify_user_location, :edit_user_registration, { alert: "location"}, "registrations"

    # User don't have a legacy password, verify if profile is valid before request to change it
    if self.has_legacy_password?
      issue ||= check_issue self.invalid?, :edit_user_registration, nil, "registrations"

      issue ||= check_issue true, :new_legacy_password, { alert: "legacy_password" }, "legacy_password"
    end

    if Rails.application.secrets.features["verification_sms"]
      # User has confirmed SMS code
      issue ||= check_issue self.sms_confirmed_at.nil?, :sms_validator_step1, { alert: "confirm_sms" }, "sms_validator"
    end

    if issue || only_blocking  # End of blocking issues
      return issue
    end

    issue ||= check_issue self.vote_town_notice, :edit_user_registration, { notice: "vote_town"}, "registrations"

    if issue
      return issue
    end
  end

  attr_accessor :sms_user_token_given
  attr_accessor :login
  attr_accessor :skip_before_save

  scope :all_with_deleted, -> { where "deleted_at IS null AND deleted_at IS NOT null"  }
  scope :wants_newsletter, -> {where(wants_newsletter: true)}
  scope :created, -> { where(deleted_at: nil)  }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :admins, -> { where(admin: true) }
  scope :unconfirmed_mail, -> { where(confirmed_at: nil)  }
  scope :unconfirmed_phone, -> { where(sms_confirmed_at: nil) }
  scope :confirmed_mail, -> { where.not(confirmed_at: nil) }
  scope :confirmed_phone, -> { where.not(sms_confirmed_at: nil) }
  scope :legacy_password, -> { where(has_legacy_password: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil).where.not(sms_confirmed_at: nil) }
  scope :signed_in, -> { where.not(sign_in_count: nil) }
  scope :participation_team, -> { includes(:participation_team).where.not(participation_team_at: nil) }
  scope :has_circle, -> { where("circle IS NOT NULL") }

  scope :verified_presencial, -> { where.not(verified_by: nil) }
  scope :unverified_presencial, -> { where(verified_by: nil).where(sms_confirmed_at: nil)}
  scope :voting_right, -> { where("verified_by_id IS NOT NULL OR sms_confirmed_at IS NOT NULL") }

  scope :has_collaboration, -> { joins(:collaboration).where("collaborations.user_id IS NOT NULL") }
  scope :has_collaboration_credit_card, -> { joins(:collaboration).where('collaborations.payment_type' => 1) }
  scope :has_collaboration_bank_national, -> { joins(:collaboration).where('collaborations.payment_type' => 2) }
  scope :has_collaboration_bank_international, -> { joins(:collaboration).where('collaborations.payment_type' => 3) }

  ransacker :vote_province, formatter: proc { |value|
    Carmen::Country.coded("ES").subregions[(value[2..3].to_i-1)].subregions.map {|r| r.code }
  } do |parent|
    parent.table[:vote_town]
  end

  ransacker :vote_autonomy, formatter: proc { |value|
    spain = Carmen::Country.coded("ES")
    Podemos::GeoExtra::AUTONOMIES.map { |k,v| spain.subregions[k[2..3].to_i-1].subregions.map {|r| r.code } if v[0]==value } .compact.flatten
  } do |parent|
    parent.table[:vote_town]
  end

  ransacker :vote_island, formatter: proc { |value|
    Podemos::GeoExtra::ISLANDS.map {|k,v| k if v[0]==value} .compact
  } do |parent|
    parent.table[:vote_town]
  end

  DOCUMENTS_TYPE = [["DNI", 1], ["NIE", 2], ["Pasaporte", 3]]

  # Based on
  # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
  # Check if login is email or document_vatid to use the DB indexes
  #
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      login_key = login.downcase.include?("@") ? "email" : "document_vatid"
      where(conditions).where(["lower(#{login_key}) = :value", { :value => login.downcase }]).take
    else
      where(conditions).first
    end
  end

  def get_or_create_vote election_id
    v = Vote.new({election_id: election_id, user_id: self.id})
    if Vote.find_by_voter_id( v.generate_message )
      return v
    else
      v.save
      return v
    end
  end

  def previous_user(force_refresh=false)
    remove_instance_variable :@previous_user if force_refresh and @previous_user
    @previous_user ||= User.with_deleted.where("lower(email) = ?", self.email.downcase).where("deleted_at > ?", 3.months.ago).last ||
                      User.with_deleted.where("lower(document_vatid) = ?", self.document_vatid.downcase).where("deleted_at > ?", 3.months.ago).last
                      User.with_deleted.where("phone = ?", self.phone).where("deleted_at > ?", 3.months.ago).last
    @previous_user
  end

  def apply_previous_user_vote_location
    if self.previous_user(true) and self.previous_user.has_verified_vote_town? and (self.vote_town != self.previous_user.vote_town)
      self.vote_town = self.previous_user.vote_town
      self.save
      true
    else
      false
    end
  end

  def document_vatid=(val)
    self[:document_vatid] = val.upcase.strip
  end

  def is_document_dni?
    self.document_type == 1
  end

  def is_document_nie?
    self.document_type == 2
  end

  def is_passport?
    self.document_type == 3
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def full_address
    "#{self.address}, #{self.town_name}, #{self.province_name}, CP #{self.postal_code}, #{self.country_name}"
  end

  def is_admin?
    self.admin
  end

  def is_valid_phone?
    self.phone? and self.confirmation_sms_sent_at? and self.sms_confirmed_at? and self.sms_confirmed_at > self.confirmation_sms_sent_at
  end

  def can_change_phone?
    self.sms_confirmed_at.nil? or self.sms_confirmed_at < DateTime.now-3.months
  end

  def self.blocked_provinces
    Rails.application.secrets.users["blocked_provinces"]
  end

  def can_change_vote_location?
    # use database version if vote_town has changed
    !self.has_verified_vote_town? or !self.persisted? or
      (Rails.application.secrets.users["allows_location_change"] and !User.blocked_provinces.member?(vote_province_persisted))
  end

  def generate_sms_token
    SecureRandom.hex(4).upcase
  end

  def set_sms_token!
    self.update_attribute(:sms_confirmation_token, generate_sms_token)
  end

  def send_sms_token!
    require 'sms'
    self.update_attribute(:confirmation_sms_sent_at, DateTime.now)
    SMS::Sender.send_message(self.unconfirmed_phone, self.sms_confirmation_token)
  end

  def check_sms_token(token)
    if token == self.sms_confirmation_token
      self.update_attribute(:sms_confirmed_at, DateTime.now)
      if self.unconfirmed_phone?
        self.update_attribute(:phone, self.unconfirmed_phone)
        self.update_attribute(:unconfirmed_phone, nil)

        if not self.verified? and not self.is_admin?
          filter = SpamFilter.any? self
          if filter
            self.update_attribute(:banned, true)
            self.add_comment("Usuario baneado automáticamente por el filtro: #{filter}")
          end
        end
      end
      true
    else
      false
    end
  end

  def phone_normalize(phone_number, country_iso=nil)
    Phoner::Country.load
    cc = country_iso.nil? ? self.country : country_iso
    country = Phoner::Country.find_by_country_isocode(cc.downcase)
    phoner = Phoner::Phone.parse(phone_number, :country_code => country.country_code)
    phoner.nil? ? nil : "00" + phoner.country_code + phoner.area_code + phoner.number
  end

  def unconfirmed_phone_number
    Phoner::Country.load
    country = Phoner::Country.find_by_country_isocode(self.country.downcase)
    if Phoner::Phone.valid?(self.unconfirmed_phone)
      phoner = Phoner::Phone.parse(self.unconfirmed_phone, :country_code => country.country_code)
      phoner.area_code + phoner.number
    else
      nil
    end
  end

  def phone_prefix
    if self.country.length < 3
      Phoner::Country.load
      begin
        Phoner::Country.find_by_country_isocode(self.country.downcase).country_code
      rescue
        "34"
      end
    else
      "34"
    end
  end

  def phone_country_name
    if Phoner::Phone.valid?(self.phone)
      Phoner::Country.load
      country_code = Phoner::Phone.parse(self.phone).country_code
      Carmen::Country.coded(Phoner::Country.find_by_country_code(country_code).char_3_code).name
    else
      Carmen::Country.coded(self.country).name
    end
  end

  def phone_no_prefix
    phone = Phoner::Phone.parse(self.phone)
    phone.area_code + phone.number
  end

  def document_type_name
    User::DOCUMENTS_TYPE.select{|v| v[1] == self.document_type }[0][0]
  end

  def in_spain?
    self.country=="ES"
  end

  def country_name
    if _country
      _country.name
    else
      self.country or ""
    end
  end

  def province_name
    if _province
      _province.name
    else
      self.province or ""
    end
  end

  def province_code
    if self.in_spain? and _province
      "p_%02d" % + _province.index
    else
      ""
    end
  end

  def town_name
    if self.in_spain? and _town
      _town.name
    else
      self.town or ""
    end
  end

  def autonomy_code
    if self.in_spain? and _province
      Podemos::GeoExtra::AUTONOMIES[self.province_code][0]
    else
      ""
    end
  end

  def autonomy_name
    if self.in_spain? and _province
      Podemos::GeoExtra::AUTONOMIES[self.province_code][1]
    else
      ""
    end
  end

  def island_code
    if self.in_spanish_island?
      Podemos::GeoExtra::ISLANDS[self.town][0]
    else
      ""
    end
  end

  def island_name
    if self.in_spanish_island?
      Podemos::GeoExtra::ISLANDS[self.town][1]
    else
      ""
    end
  end

  def in_spanish_island?
    (self.in_spain? and Podemos::GeoExtra::ISLANDS.has_key? self.town) or false
  end

  def vote_in_spanish_island?
    (Podemos::GeoExtra::ISLANDS.has_key? self.vote_town) or false
  end

  def has_vote_town?
    not self.vote_town.nil? and not self.vote_town.empty? and not self.vote_town=="NOTICE"
  end

  def has_verified_vote_town?
    self.has_vote_town? and self.vote_town[0]=="m"
  end

  def vote_autonomy_code
    if _vote_province
      Podemos::GeoExtra::AUTONOMIES[self.vote_province_code][0]
    else
      ""
    end
  end

  def vote_autonomy_name
    if _vote_province
      Podemos::GeoExtra::AUTONOMIES[self.vote_province_code][1]
    else
      ""
    end
  end

  def vote_town_name
    if _vote_town
      _vote_town.name
    else
      ""
    end
  end

  def vote_province_persisted
    prov = _vote_province
    if self.vote_town_changed?
      begin
        previous_province = Carmen::Country.coded("ES").subregions[self.vote_town_was[2,2].to_i-1]
        prov = previous_province if previous_province
      rescue
      end
    end

    if prov
      prov.code
    else
      ""
    end
  end

  def vote_province
    if _vote_province
      _vote_province.code
    else
      ""
    end
  end

  def vote_province= value
    if value.nil? or value.empty? or value == "-"
      self.vote_town = nil
    else
      prefix = "m_%02d_"% (Carmen::Country.coded("ES").subregions.coded(value).index)
      if self.vote_town.nil? or not self.vote_town.starts_with? prefix then
        self.vote_town = prefix
      end
    end
  end

  def vote_province_code
    if _vote_province
      "p_%02d" % + _vote_province.index
    else
      ""
    end
  end

  def vote_province_name
    if _vote_province
      _vote_province.name
    else
      ""
    end
  end


  def vote_island_code
    if self.vote_in_spanish_island?
      Podemos::GeoExtra::ISLANDS[self.vote_town][0]
    else
      ""
    end
  end

  def vote_island_name
    if self.vote_in_spanish_island?
      Podemos::GeoExtra::ISLANDS[self.vote_town][1]
    else
      ""
    end
  end

  def vote_autonomy_numeric
    if _vote_province
      self.vote_autonomy_code[2..-1]
    else
      "-"
    end
  end

  def vote_province_numeric
    if _vote_province
      "%02d" % + _vote_province.index
    else
      ""
    end
  end

  def vote_town_numeric
    if _vote_town
      _vote_town.code.split("_")[1,3].join
    else
      ""
    end
  end

  def vote_island_numeric
    if self.vote_in_spanish_island?
      self.vote_island_code[2..-1]
    else
      ""
    end
  end

  def verify_user_location()
    return "country" if not _country
    return "province" if not _country.subregions.empty? and not _country.subregions.coded(self.province)
    return "town" if self.in_spain? and not _town
  end

  def vote_town_notice()
    self.vote_town == "NOTICE"
  end

  def self.get_location(current_user, params)
    # params from edit page
    user_location = { country: params[:user_country], province: params[:user_province], town: params[:user_town], vote_town: params[:user_vote_town], vote_province: params[:user_vote_province] }

    # params from create page
    if params[:user]
      user_location[:country] ||= params[:user][:country]
      user_location[:province] ||= params[:user][:province]
      user_location[:town] ||= params[:user][:town]
      user_location[:vote_town] ||= params[:user][:vote_town]
      user_location[:vote_province] ||= params[:user][:vote_province]
    end

    # params from user profile
    if (params[:no_profile]==nil) && current_user && current_user.persisted?
      user_location[:country] ||= current_user.country
      user_location[:province] ||= current_user.province
      user_location[:town] ||= current_user.town.downcase

      if current_user.has_vote_town?
        user_location[:vote_town] ||= current_user.vote_town
        user_location[:vote_province] ||= Carmen::Country.coded("ES").subregions.coded(current_user.vote_province).code
      else
        user_location[:vote_town] ||= "-"
        user_location[:vote_province] ||= "-"
      end
    end

    # default country
    user_location[:country] ||= "ES"

    user_location
  end

  def self.ban_users ids, value
    t = User.arel_table
    User.where(id:ids).where(t[:admin].eq(false).or(t[:admin].eq(nil))).update_all User.set_flag_sql(:banned, value)
  end

  def before_save
    unless @skip_before_save
      # Spanish users can't set a different town for vote, except when blocked
      if self.in_spain? and self.can_change_vote_location?
        self.vote_town = self.town
      end
    end
  end

  def in_participation_team? team_id
    self.participation_team_ids.member? team_id
  end

  def admin_permalink
    admin_user_path(self)
  end

  def _clear_caches
    remove_instance_variable :@country_cache if defined? @country_cache
    remove_instance_variable :@province_cache if defined? @province_cache
    remove_instance_variable :@town_cache if defined? @town_cache
    remove_instance_variable :@vote_province_cache if defined? @vote_province_cache
    remove_instance_variable :@vote_town_cache if defined? @vote_town_cache
  end

  def _country
    @country_cache ||= Carmen::Country.coded(self.country)
  end

  def _province
    @province_cache = begin
      prov = nil
      prov = _country.subregions[self.town[2,2].to_i-1] if self.in_spain? and self.town and self.town.downcase.starts_with? "m_"
      prov = _country.subregions.coded(self.province) if prov.nil? and _country and self.province and not _country.subregions.empty?
      prov
    end if not defined? @province_cache
    @province_cache
  end

  def _town
    @town_cache = begin
      town = nil
      town = _province.subregions.coded(self.town) if self.in_spain? and _province
      town
    end if not defined? @town_cache
    @town_cache
  end

  def _vote_province
    @vote_province_cache = begin
      prov = nil
      if self.has_vote_town?
        prov = Carmen::Country.coded("ES").subregions[self.vote_town[2,2].to_i-1]
      elsif self.country=="ES"
        prov = _province
      else
        prov = nil
      end
      prov
    end if not defined? @vote_province_cache
    @vote_province_cache
  end

  def _vote_town
    @vote_town_cache = begin
      town = nil
      if self.has_vote_town?
        town = _vote_province.subregions.coded(self.vote_town)
      elsif self.country=="ES"
        town = _town
      else
        prov = nil
      end
      town
    end if not defined? @vote_town_cache
    @vote_town_cache
  end

  def is_verified?
    if Rails.application.secrets.features["verification_presencial"]
      self.verified_by_id?
    else
      self.verified?
    end
  end

  def verify! user
    self.verified_at = DateTime.now
    self.verified_by = user
    self.save
    VerificationMailer.verified(self).deliver
  end

end
