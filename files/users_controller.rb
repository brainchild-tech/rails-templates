class Api::V1::UsersController < Api::V1::BaseController

  def show
    current_user = User.find(params[:id])
    render json: current_user, adapter: :json
  end

  def update
    user = current_user
    if user.update(user_params)
      render json: user, adapter: :json
    else
      render_error(user)
    end
  end

  def get_phone
    # needs customization depending on user journey
    user = current_user
    data = phone_params[:encryptedData]
    iv = phone_params[:iv]

    sesskey = Base64.decode64(user.session_key)
    data = Base64.decode64(data)
    iv = Base64.decode64(iv)

    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = sesskey
    decipher.iv = iv

    plain = decipher.update(data) + decipher.final

    phone = JSON.parse(plain)['phoneNumber']
    puts "phone ==>> #{phone}"

    # if phone.present?
    #   return phone
    # else
    #   return nil
    # end
  end

  private

  def user_params
    params.require(:user).permit(:avatar, :nickname, :gender, :city, :country, :language, :province, :email, :phone_number, :is_admin)
  end

  def phone_params
    params.require(:phone).permit(:encryptedData, :iv)
  end
end
