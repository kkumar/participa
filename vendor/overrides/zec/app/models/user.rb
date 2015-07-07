
require_dependency Rails.root.join('app', 'models', 'user').to_s

class User

  validates :district, presence: true
  validates :inscription, acceptance: true

  DISTRICT = [["Actur-Rey Fernando", 1], ["Casablanca", 2], ["Casco Histórico", 3], ["Centro", 4], ["Delicias", 5], ["El Rabal", 6], ["La Almozara", 7], ["Las Fuentes", 8], ["Miralbueno", 9], ["Oliver-Valdefierro", 0], ["San José", 11], ["Santa Isabel", 12], ["Torrero", 13], ["Universidad", 14], ["Barrios Rurales", 15]]

  def district_name
    User::DISTRICT.select{|v| v[1] == self.district }[0][0]
  end

  validates :born_at, inclusion: { in: Date.civil(1900, 1, 1)..Date.today-16.years,
    message: "debes ser mayor de 16 años" }, allow_blank: true

  before_validation :set_location

  def set_location 
    self.country = "ES"
    self.province = "ZA"
    self.town = "m_50_297_3"
  end

  def is_verified?
    if Rails.application.secrets.features["verification_presencial"]
      self.verified_by_id? or self.sms_confirmed_at?
    else
      self.verified?
    end
  end

end
