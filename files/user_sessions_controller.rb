class Api::V1::UserSessionsController < Devise::SessionsController
  before_action :authenticate_user!, except: [:create, :manual_create], raise: false
  before_action :set_locale
  skip_before_action :verify_authenticity_token

  APPID = Rails.application.credentials.dig(:wechat, :app_id)
  APPSECRET = Rails.application.credentials.dig(:wechat, :app_secret)

  def create
    user = login
    user.save!
    token = Tiddle.create_and_return_token(user, request)
    response =  {
      user: UserSerializer.new(user),
      headers: {
        "X-USER-EMAIL"=> user.email,
        "X-USER-TOKEN"=> token
      },
      tl: I18n.t('mp.static')
    }
    render json: response.merge!(@wx_auth)
  end

  def manual_create
    user = User.create!(email: params[:email], password: Devise.friendly_token(20))
    token = Tiddle.create_and_return_token(user, request)
    response =  {
      user: UserSerializer.new(user),
      headers: {
        "X-USER-EMAIL"=> user.email,
        "X-USER-TOKEN"=> token
      },
      tl: I18n.t('mp.static')
    }
    render json: response
  end

  def destroy
    Tiddle.expire_token(current_user, request) if current_user
    render json: {}
  end

  private

  def wx_verify
    app_id = APPID
    app_secret = APPSECRET
    code = params[:code]

    puts "app id #{app_id} & secret #{app_secret} "
    puts "code ==>> #{code}"

    url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{app_id}&secret=#{app_secret}&js_code=#{code}&grant_type=authorization_code"
    puts "wx_verify url: #{url}"
    response = RestClient.get(url)
    res = JSON.parse(response.body)
    puts "wx_verify result: #{res}"
    return res
  end

  # this is invoked before destroy and we have to override it
  def verify_signed_out_user
  end

  def login
    if params[:code].present?
      @wx_auth = wx_verify
      puts "wx_auth res ==>> #{@wx_auth}"
      user = get_user(@wx_auth)
    elsif params[:email].present? && params[:password].present?

    end
    return user
  end

  def get_user(wx_auth)
    openid = wx_auth["openid"]
    session_key = wx_auth["session_key"]
    user = User.find_by(open_id: openid)

    if user.blank?
      u_params = {
        email: "#{openid.downcase}_#{SecureRandom.hex(3)}@wx.com",
        open_id: openid,
        session_key: session_key,
        password: Devise.friendly_token(20)
      }
      user = User.create!(u_params)
    else
      user.update(session_key: session_key)
    end
    puts "USER #{user}"
    user
  end

  def render_error(object)
    render json: { status: 'fail', res: 'fail', errors: object.errors.full_messages }, status: 422
  end

  def set_locale
    # I18n.locale = params.fetch(:locale, I18n.default_locale).to_sym || "en".to_sym
    I18n.locale = params[:locale].present? ? params[:locale].to_sym : :en
  end
end
