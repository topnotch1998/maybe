class Settings::SelfHostingController < ApplicationController
  before_action :verify_self_hosting_enabled

  def edit
  end

  def update
    if all_updates_valid?
      self_hosting_params.keys.each do |key|
        Setting.send("#{key}=", self_hosting_params[key].strip)
      end

      redirect_to edit_settings_self_hosting_path, notice: t(".success")
    else
      flash.now[:error] = @errors.first.message
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def all_updates_valid?
      @errors = ActiveModel::Errors.new(Setting)
      self_hosting_params.keys.each do |key|
        setting = Setting.new(var: key)
        setting.value = self_hosting_params[key].strip

        unless setting.valid?
          @errors.merge!(setting.errors)
        end
      end

      if self_hosting_params[:upgrades_mode] == "auto" && self_hosting_params[:render_deploy_hook].blank?
        @errors.add(:render_deploy_hook, t("settings.self_hosting.update.render_deploy_hook_error"))
      end

      @errors.empty?
    end

    def self_hosting_params
      params.require(:setting).permit(:render_deploy_hook, :upgrades_mode, :upgrades_target)
    end

    def verify_self_hosting_enabled
      head :not_found unless self_hosted?
    end
end
