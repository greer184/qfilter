class DemoController < ApplicationController

  def stake
    @feed = poll_blockchain('stake')
    render 'index'
  end
  
  def reputation
    @feed = poll_blockchain('reputation')
    render 'index'
  end

  def contribution
    @feed = poll_blockchain('contribution')
    render 'index'
  end

  private
  def poll_blockchain(calculation)
    feed = []
    api = Radiator::Api.new

    Post.all.each do |post|

      # Obtain Content For Specific Post
      content = api.get_content(post.author, post.permlink)
      info = Hash.new

      # Display Information
      info['url'] = "https://steemit.com" + content['result']['url']
      info['title'] = content['result']['root_title']
      info['author'] = content['result']['author']
      info['image'] = JSON.parse(content['result']['json_metadata'])['image'][0]

      # Score Calculation
      total = 0   
      weights = 1000.0
      volatility = 0
      alpha = 0.1
      content['result']['active_votes'].sort_by{ |x| x['time'] }.each do |y|

        case calculation
        when 'stake'
          weight = y['weight'].to_f
        when 'reputation'
          weight = y['reputation'].to_f
        when 'contribution'
          weight = 0
        end

        rating = (y['percent'] + 10000.0) / 2000
        total += weight * rating
        weights += weight
        volatility = alpha * (rating-total/weights)**2 + volatility * (1-alpha)

      end
      info['score'] = (total / weights / (volatility / 100 + 1)).round(2)

      feed.append(info)
    end
    feed
  end
end
