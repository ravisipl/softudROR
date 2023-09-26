class Api::V1::EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: %i[ show edit update destroy ]
  include EmailTemplatesHelper

  # GET /email_templates or /email_templates.json
  def index
    @email_templates = EmailTemplate.all
  end

  # GET /email_templates/1 or /email_templates/1.json
  def show
  end

  # GET /email_templates/new
  def new
    @email_template = EmailTemplate.new
  end

  # GET /email_templates/1/edit
  def edit
  end

  # POST /email_templates or /email_templates.json

  def create
    @email_template = EmailTemplate.new(email_template_params)
    @email_template.created_by = current_user.id
    respond_to do |format|
      if @email_template.save
        format.html { redirect_to admin_email_template_path(@email_template), notice: "Email template was successfully created." }
        format.json { render :show, status: :created, location: @email_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def send_email_template
    template_slug = "welcome"
    user_id = params[:id]
    placeholders = {
      "STUDENT_NAME" => User.find(user_id).username,
    }

    result = send_email_by_email_template(template_slug, user_id, placeholders)
    if result
      render plain: "Email sent successfully."
    else
      render plain: "Email template not found."
    end
  end

  def send_order_template
    template_slug = "order"
    user_id = params[:id]
    order_template = Order.find_by(user_id: user_id)
    order_details = order_template.order_detail

    if order_details.present?
      placeholders = {
        "USER_NAME" => order_template.billing_first_name,
        "ORDER_ITEM" => order_details.product_name,
        "ORDER_TOTAL" => order_template.order_total.to_i,
        "ORDER_SHIPPING" => order_template.shipping_address,
      }

      result = send_email_by_email_template(template_slug, user_id, placeholders)

      if result
        render plain: "Email sent successfully."
      else
        render plain: "Email template not found."
      end
    else
      render plain: "Order details not found."
    end
  end

  # PATCH/PUT /email_templates/1 or /email_templates/1.json
  def update
    @email_template.updated_by = current_user.id

    respond_to do |format|
      if @email_template.update(email_template_params)
        format.html { redirect_to admin_email_template_path(@email_template), notice: "Email template was successfully updated." }
        format.json { render :show, status: :ok, location: @email_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_email_template_list
    begin
      email_template = EmailTemplate.datatable_filter(params["search"]["value"], params["columns"])
      email_template_filtered = email_template.count
      email_template = email_template.datatable_order(params["order"]["0"]["column"].to_i,
                                                      params["order"]["0"]["dir"])
      email_template = email_template.offset(params[:start]).limit(params[:length])
      render json: { data: email_template,
                     draw: params["draw"].to_i,
                     recordsTotal: EmailTemplate.count,
                     recordsFiltered: email_template_filtered }
    rescue => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end
  end

  def email_template_status
    @email_template = EmailTemplate.find(params[:id])
    if (@email_template.status == true)
      @email_template.update(status: 0)
      @email_template.deleted_at = Time.zone.now
      @email_template.updated_by = current_user.id
      @email_template.deleted_by = current_user.id
      @email_template.save
    else
      @email_template.update(status: 1)
      @email_template.deleted_at = nil
      @email_template.updated_by = current_user.id
      @email_template.deleted_by = current_user.id
      @email_template.save
    end
  end

  # DELETE /email_templates/1 or /email_templates/1.json
  def destroy
    @email_template.destroy

    respond_to do |format|
      format.html { redirect_to email_templates_url, notice: "Email template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def email_template_params
    params.require(:email_template).permit(:email_title, :email_content, :email_subject)
  end
end
