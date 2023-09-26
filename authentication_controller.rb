class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_action :authorize_request, except: :login

  # POST /auth/login
  def login
    begin
      #user = User.find_by_email(params[:email])
      user = User.where(email: params[:email]).first
      if user.present?
        if user.deleted_at == nil
          if user.status != 0
            if user.role != "coach"
              if user && user.valid_password?(params[:password])
                token = JsonWebToken.encode(user_id: user.id)
                session[:current_user_id] = user.id
                user.update_attribute(:reset_password_token, token)
                time = Time.now + 24.hours.to_i
                @user = User.joins(:user_detail).select("users.*,user_details.*").where(id: user.id).first
                object_to_send = @user.attributes.merge(:role_id => User.roles[user.role])
                render json: { message: "Login Successfull", data: { token: token, exp: time.strftime("%m-%d-%Y %H:%M"), user_data: object_to_send } }, status: :ok
              else
                render json: { errors: "Invalid Password" }, status: :precondition_failed
              end
            else
              render json: { errors: "You can't login with Coach" }, status: :precondition_failed
            end
          else
            render json: { errors: "Your account status is deactivated contact to administrator" }, status: :precondition_failed
          end
        else
          render json: { errors: "Your account is deleted contact to administrator" }, status: :precondition_failed
        end
      else
        render json: { errors: "Invalid Email" }, status: :precondition_failed
      end
    rescue Exception => e
      render json: { message: e.message }, status: :unprocessable_entity
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
