class Post < ApplicationRecord

  def self.aggregate_posts(algorithm, category = nil)
    feed = []
    api = Radiator::Api.new

    # Build feeds, checking categories option
    if category.nil?
      Post.all.each do |post|
        feed.append(post.build_post(algorithm, api))
      end
    else
      Post.all.each do |post|
        if (post.category == category)
          feed.append(post.build_post(algorithm, api))
        end
      end
    end

    feed
  end

  def build_post(algorithm, api)

    # Obtain Content For Specific Post
    content = api.get_content(self.author, self.permlink)
    info = Hash.new

    # Display Information
    info['url'] = "https://steemit.com" + content['result']['url']
    info['title'] = content['result']['root_title']
    info['author'] = content['result']['author']
    info['votes'] = content['result']['active_votes'].size
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
    total = 0.0   
    variance = 0.0
    weights = 1000.0
    count = 0
    penalty = 25
    negative = false

    # Make sure votes exist, otherwise return 0.
    return 0.0 if votes.count == 0

    # Go through votes
    votes.sort_by{ |x| x['time'] }.each do |y|

      weight = 0.0
      case algorithm
      when 'stake'
        weight = y['weight'].to_f
      when 'reputation'
        weight = y['reputation'].to_f
      when 'contribution', 'curation', 'vote'
        
        # Add voter to database if not there
        Contributor.add_contributor(y['voter'])

        # Select weight from voter
        con = Contributor.find_by_username(y['voter'])
        if con.weight > 0
          weight += con.weight
          if (y['percent'] < 0.0 and algorithm == 'vote')
            negative = true
          end
        end
          
      end

      # Weighted Average
      rating = (y['percent'] + 10000.0) / 2000
      total += weight * rating
      weights += weight
 
    end

    average = total / weights

    # Calculate Variance
    votes.each do |x|
      variance += (average - ((x['percent'] + 10000.0) / 2000))**2
    end
    variance /= votes.count.to_f

    # Final Score
    score = (average / ((variance / penalty) + 1)).round(2) 

    if algorithm == 'curation'
      min_difference = 10
      winner = ''
      votes.each do |x|
        random = SecureRandom.random_number
        beta = (votes.count - count) / votes.count
        wager = beta * ((x['percent'] + 10000.0) / 2000) + (1 - beta) * random 
        difference = wager - score
        if difference < min_difference and x['voter'] != 'qfilter'
          min_difference = difference
          winner = x['voter']
        end 
        count += 1
      end
      score = winner
    end

    # If no flags, but score below 5.0
    # lower bound = 5.0
    if !negative and algorithm == 'vote'
      if score < 5.0
        score = 5.0
      end
    end

    score
  end
  
end
