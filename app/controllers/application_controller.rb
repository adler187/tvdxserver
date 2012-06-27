class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def authenticate
    if CONFIG['perform_authentication']
      authenticate_or_request_with_http_basic do |username, password|
        username == CONFIG['username'] && password == CONFIG['password']
      end
    end
  end
end
