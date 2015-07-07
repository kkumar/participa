class SetLocationToUsers < ActiveRecord::Migration
  def change
    User.update_all(country: "ES")
    User.update_all(province: "B")
    User.update_all(town: "m_08_019_3")
  end
end
