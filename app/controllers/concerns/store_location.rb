module StoreLocation
  extend ActiveSupport::Concern

  included do
    helper_method :previous_path
    before_action :store_return_to
    after_action :clear_previous_path
  end

  def previous_path
    session[:return_to] || fallback_path
  end

private

  def store_return_to
    if params[:return_to].present?
      session[:return_to] = params[:return_to]
    end
  end

  def clear_previous_path
    if request.fullpath == session[:return_to]
      session.delete(:return_to)
    end
  end

  def fallback_path
    root_path
  end
end
