class Api::V1::BaseController < ActionController::Base
  serialization_scope :view_context
  # protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token
  before_action :set_locale
  before_action :authenticate_user!

  APP_ID = Rails.application.credentials.dig(:wechat, :app_id)
  APP_SECRET = Rails.application.credentials.dig(:wechat, :app_secret)

  def wx_fetch_token
    app_id = APP_ID
    app_secret = APP_SECRET
    url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{app_id}&secret=#{app_secret}"

    @wechat_response ||= RestClient.get(url)
    JSON.parse(@wechat_response.body).fetch("access_token")
  end

  def render_error(object)
    render json: { status: 'fail', res: 'fail', errors: object.errors.full_messages }, status: :unprocessable_entity
  end

  def check_admin_permission
    unless current_user.is_admin
      render json: {
        errors: "User has no admin authorization."
      }
    end
  end

  def decrypt(user, data, iv)
    sesskey = Base64.decode64(user.session_key)
    data = Base64.decode64(data)
    iv = Base64.decode64(iv)

    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = sesskey
    decipher.iv = iv

    plain = decipher.update(data) + decipher.final
    puts plain
    JSON.parse(plain)
  end

  private

  def check_headers
    puts response.headers
  end

  def set_locale
    # I18n.locale = params.fetch(:locale, I18n.default_locale).to_sym || "en".to_sym
    I18n.locale = params[:locale].present? ? params[:locale].to_sym : :en
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def internal_server_error(exception)
    if Rails.env.development?
      response = { type: exception.class.to_s, error: exception.message }
    else
      response = { error: "Internal Server Error" }
    end
    render json: response, status: :internal_server_error
  end

  def tl
    I18n.t('mp')
  end

  def blob_link(x)
    host = HOST
    Rails.application.routes.url_helpers.rails_blob_url(x, host: host)
  end

  # def active_tab
  #   # Overwrite method in each individual controller.
  #   # Let's say in controller for 2nd tab:
  #   # ex:  return 1
  #   #
  #   return 0
  # end

  # Intelligent Model-Fetching from Kablam codebase.
  # table-name should be the params in url.

end
