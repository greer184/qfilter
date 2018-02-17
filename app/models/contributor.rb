class Contributor < ApplicationRecord

  def Contributor.add_contributor(user)
    if Contributor.where(username: user).size == 0
      Contributor.create(username: user, score: 1000, checkpoint: 0).save
    end
  end

  def Contributor.find_best(number)
    list = []
    Contributor.all.each do |x|
      list.append([x, x.weight])
    end
    sorted = list.sort_by{ |x| x[1] }.reverse
    final = sorted.map{ |x| x = x[0] }
    final.take(number)
  end

  def Contributor.normalize()
    factor = (Contributor.all.count * 1000.0) / Contributor.sum(:weight) 
    Contributor.all.each do |con|
      con.update_attribute(:weight, con.weight * factor)
    end
  end 

end
