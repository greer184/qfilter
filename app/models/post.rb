class Post < ApplicationRecord

  def build_post(algorithm, api)

    # Obtain Content For Specific Post
    content = api.get_content(self.author, self.permlink)
    info = Hash.new

    # Display Information
    info['url'] = "https://steemit.com" + content['result']['url']
    info['title'] = content['result']['root_title']
    info['author'] = content['result']['author']
    image = JSON.parse(content['result']['json_metadata'])['image']
    if !image.nil?
      info['image'] = image[0]
    end

    # Score Calculation
    info['score'] = compute_score(algorithm, content['result']['active_votes'])

    info
  end

  def compute_score(algorithm, votes)
 
    # Working variables 
    total = 0   
    count = 1
    weights = 1000.0
    volatility = 0
    alpha = 0.1

    # Go through votes
    votes.sort_by{ |x| x['time'] }.each do |y|
      weight = 0.0
      case algorithm
      when 'stake'
        weight = y['weight'].to_f
      when 'reputation'
        weight = y['reputation'].to_f
      when 'contribution'
        con = Contributor.find_by_username(y['voter'])
        if !con.nil?
          weight += con.score
        end
      when 'curation'
        alpha = (Math.exp(-2 * count / votes.size))
        random = SecureRandom.random_number
        weight = y['weight'].to_f * (alpha + (1-alpha) * random)
        count += 1
      end

      rating = (y['percent'] + 10000.0) / 2000
      total += weight * rating
      weights += weight
      volatility = alpha * (rating-total/weights)**2 + volatility * (1-alpha)

    end

    score = (total / weights / (volatility / 100 + 1)).round(2)

    if algorithm == 'curation'
      min_difference = 100
      winner = ''
      votes.each do |x|
        difference = (((x['percent'] + 10000.0) / 2000) - score)**2
        if difference < min_difference
          min_difference = difference
          winner = x['voter']
        end 
      end
      score = winner
    end

    score
  end
end
