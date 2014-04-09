class OctoClient
  def self.set_expire redis,key
    redis.expire(key,30)
  end

  def self.generate_key query,order = nil, page=nil
    redisBaseKey = "gitsearch:#{query}"
    
    if page && page != ''
      redisBaseKey = "#{redisBaseKey}:#{page}"
    end

    if order && order != ''
      redisBaseKey = "#{redisBaseKey}:#{order}"
    end

    return redisBaseKey
  end

  def self.language_key query
    "gitsearch:#{query}:languages"
  end
  def self.generate_count_key query,order
    return "#{generate_key(query,order)}:total_count"
  end

  def self.search query,page,order,access_token
    redis = $redis
    redisKey= self.generate_key(query,order,page)
    puts "SEARCH KEY: #{redisKey}"
    begin
      items = JSON.parse(redis.get(redisKey))
      puts "Cache hit"
    rescue #from a nil response from redis, indicating a cache miss
      puts "Cache miss"
      begin
        per_page = 90
        git_search_page = ((page-1)/3) + 1
        params = { :q => query,:per_page => per_page,:order => order,:sort=> :stars, :access_token => access_token,:page => page }
        response = self.make_request params
        puts "API SEARCH PAGE:#{git_search_page}"
        puts response["items"].size
        pages = response["items"].in_groups_of(30)
        offset = 0
        pages.each do |a_page|
          redisKey = self.generate_key(query,order,page+offset)
          a_page.each do |a_item|
            redis.sadd(language_key(query),a_item["language"])
          end
          items = a_page.to_json
          puts "Adding: #{redisKey}"
          puts redis.set(redisKey,items)
          self.set_expire redis,redisKey
          offset = offset+1
        end
        num_items = response["total_count"]
        redis.set(generate_count_key(query,order),num_items)
        self.set_expire redis,generate_count_key(query,order)
        items = JSON.parse(items)
      rescue Exception => e# from a rejection from the github API. err thrown through gem
        puts "GITHUB ERROR! #{e}"
        items = [] 
      end
    end 
    return items
  end
  def self.get_languages query
    redis = $redis
    @languages = redis.smembers(language_key(query))
    redis.expire(language_key(query),90)
    return @languages
  end
  def self.get_count query,order
    begin
      redis = $redis
      key = generate_count_key(query,order)
      count = redis.get(key).to_i
    rescue
      count = -1
    end
    return count.to_i
  end
  def self.generate_url params
    url = "https://api.github.com/search/repositories?"
    if params[:access_token]
      url = "#{url}access_token=#{params[:access_token]}&"
    end
    url = "#{url}q=#{params[:q]}"

    if params[:order] != ''
      if params[:sort]
        url = "#{url}&sort=#{params[:sort]}"
        url = "#{url}&order=#{params[:order]}"
      end
    end
    if params[:page]
      url = "#{url}&page=#{params[:page]}"
    end

    if params[:per_page]
      url = "#{url}&per_page=#{params[:per_page]}"
    end
    puts "URL: #{url}"
    return url
  end
  def self.make_request params
    url = self.generate_url params
    uri = URI.parse(url)
    connection = Net::HTTP.new(uri.host, 443)
    connection.use_ssl = true
    puts "MAKING REQUEST: params = #{uri.query}"
    resp = connection.request_get(uri.path + '?' + uri.query)

    if resp.code != '200'
      raise "web service error"
    end

    return JSON.parse(resp.body)  
  end
end
