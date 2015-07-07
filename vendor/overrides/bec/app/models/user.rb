
require_dependency Rails.root.join('app', 'models', 'user').to_s

class User

  validates :district, presence: true
  validates :inscription, acceptance: true

  DISTRICT = [["Ciutat Vella", 1], ["Eixample", 2], ["Sants-Montjuïc", 3], ["Les Corts", 4], ["Sarrià-Sant Gervasi", 5], ["Gràcia", 6], ["Horta-Guinardó", 7], ["Nou Barris", 8], ["Sant Andreu", 9], ["Sant Martí", 0]]

  def district_name
    User::DISTRICT.select{|v| v[1] == self.district }[0][0]
  end

  validates :born_at, inclusion: { in: Date.civil(1900, 1, 1)..Date.today-16.years,
    message: "debes ser mayor de 16 años" }, allow_blank: true

  before_validation :set_location

  def set_location 
    self.country = "ES"
    self.province = "B"
    self.town = "m_08_019_3"
  end

  def is_verified?
    if Rails.application.secrets.features["verification_presencial"]
      self.verified_by_id? or self.sms_confirmed_at?
    else
      self.verified?
    end
  end

end
