class Contributor < ApplicationRecord

  def Contributor.add_contribution(user, value)
    if Contributor.where(username: user).size == 0
      Contributor.create(username: user, score: value, checkpoint: 0).save
    else
      con = Contributor.find_by_username(user)
      con.update_attribute(:score, con.score + value)
    end
  end

  def Contributor.find_best(number)
    list = []
    Contributor.all.each do |x|
      list.append([x, x.score - x.checkpoint])
    end
    sorted = list.sort_by{ |x| x[1] }.reverse
    final = sorted.map{ |x| x = x[0] }
    final.take(number)
  end

end
