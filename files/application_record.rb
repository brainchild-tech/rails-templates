class ApplicationRecord < ActiveRecord::Base
  mattr_accessor :token
  mattr_accessor :token_time
  self.abstract_class = true

  LOCALE = I18n.locale
  # ================= DATE FORMATTING  =================== #
  CN_HASH = {
    'Monday'=> '周一',
    'Tuesday'=> '周二',
    'Wednesday'=> '周三',
    'Thursday'=> '周四',
    'Friday'=> '周五',
    'Saturday'=> '周六',
    'Sunday'=> '周日',
  }

  def get_locale
    I18n.locale
  end

  def time_format(date)
    I18n.locale == :en ? date.in_time_zone("Beijing").strftime('%l:%M%p').squeeze(' ').strip.downcase : date.in_time_zone("Beijing").strftime('%p%l:%M').squeeze(' ').strip.gsub("AM","上午").gsub("PM","下午").gsub(" ", "")
  end

  def start_day_format(date)
    locale = I18n.locale
    today = bj_time_now.in_time_zone("Beijing").strftime('%Y-%m-%d')
    tmr = (bj_time_now + 1.days).in_time_zone("Beijing").strftime('%Y-%m-%d')
    event_date = date.in_time_zone("Beijing").strftime('%Y-%m-%d')
    if today == event_date
      locale == :en ? 'Today' : '今天'
    elsif tmr == event_date
      locale == :en ? 'Tomorrow' : '明天'
    else
      nil
      # locale == :en ? date.in_time_zone("Beijing").strftime('%A, %B %d') : "#{CN_HASH[date.in_time_zone("Beijing").strftime('%A')]} #{date.in_time_zone("Beijing").strftime('%m月%e日').gsub(/(^0|\s)/, "")}"
    end
  end

  def bj_time_now
    Time.now.in_time_zone("Beijing")
  end

  # ================== IMAGE PROCESSING ================== #

  def blob_link(x)
    host = DOMAIN
    Rails.application.routes.url_helpers.rails_blob_url(x, host: host)
  end

  # =========== ALIYUN OSS IMG PROCESSING ============ #

  def thumb_path(img)
    img.service_url(params: {'x-oss-process'=> 'style/thumb'}) if img.content_type.include?("image")
  end

  def med_path(img)
    return img.service_url(params: {'x-oss-process'=> 'style/med'}) if img.content_type.include?("image")
  end

  def large_path(img)
    img.service_url(params: {'x-oss-process'=> 'style/large'}) if img.content_type.include?("image")
  end

  # ========================= WX TOKEN ========================== #
  APP_ID = Rails.application.credentials.dig(:wechat, :app_id)
  APP_SECRET = Rails.application.credentials.dig(:wechat, :app_secret)

  def self.wx_fetch_token
    self.get_token
  end

  def self.token_expired?
    puts "inside token_expired?"
    puts "token exists? ==> #{self.token}"
    return true if self.token.nil?
    expiration = self.token_time + 110.minutes
    return false if expiration > Time.now
    return true
  end

  def self.get_token
    if self.token_expired?
      puts "token expired"
      # p "=======token expired, get new one"
      return self.set_token
    end
    return self.token
  end

  def self.set_token
    puts "set new token"
    token_url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{APP_ID}&secret=#{APP_SECRET}"
    result = RestClient.get(token_url)
    # p "===============set token"
    r = JSON.parse(result)
    # p r
    if !r["access_token"].nil?
      # p "============get token========"
      self.token_time = Time.now
      self.token = r["access_token"]
    else
      p 'get token failed'
      p r
    end
  end
end
