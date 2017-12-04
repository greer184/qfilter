class Contributor < ApplicationRecord

  def Contributor.add_contribution(user, value)
    if Contributor.where(username: user).size == 0
      Contributor.create(username: user, score: value).save
    else
      con = Contributor.find_by_username(user)
      con.update_attribute(:score, con.score + value)
    end
  end

end
