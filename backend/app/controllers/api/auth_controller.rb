class Api::AuthController < ApplicationController
  def register
    user = User.new(user_params)

    if user.save
      token = generate_jwt_token(user)
      render json: { user: user_data(user), token: token }, status: :created 
    else 
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = generate_jwt_token(user)
      render json: { user: user_data(user), token: token }
    else
      render json: { error: 'invalid credentials' }, status: :unauthorized
    end
  end

  def me
    if current_user
      render json: { user: user_data(current_user) }
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name)
  end

  def user_data(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def decode_token
    auth_header = request.headers['Authorization']
    if auth_header
      token = auth_header.split(' ')[1]
      begin
        JWT.decode(token, Rails.application.secret_key_base)[0]
      rescue JWT::DecodeError
        nil
      end
    end
  end

  def current_user
    decoded_token = decode_token
    if decoded_token
      user_id = decoded_token['user_id']
      @user = User.find_by(id: user_id)
    end
  end
end
