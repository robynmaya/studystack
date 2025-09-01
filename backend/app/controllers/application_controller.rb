class ApplicationController < ActionController::API
  before_action :set_current_user
  
  private
  
  def set_current_user
    token = request.headers['Authorization']&.split(' ')&.last
    return unless token
    
    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base)[0]
      @current_user = User.find(decoded_token['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      @current_user = nil
    end
  end
  
  def current_user
    @current_user
  end
  
  def authenticate_user!
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
  
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
