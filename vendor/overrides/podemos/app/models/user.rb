require_dependency Rails.root.join('app', 'models', 'user').to_s

class User

  validates :born_at, inclusion: { in: Date.civil(1900, 1, 1)..Date.today-18.years,
    message: "debes ser mayor de 18 años" }, allow_blank: true

end
