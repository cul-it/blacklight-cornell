class StatusController < ActionController::Base
  before_action :authenticate_with_basic_auth

  def index
    @statuses = nested_statuses
    respond_to do |format|
      format.html
      format.json { render json: @statuses }
      format.xml  { render xml: @statuses }
    end
  end

  private
  # Process and nest specific services under MyAccountStatus
  def nested_statuses
    raw_statuses = statuses

    # Extract the individual services from the raw status data
    services = raw_statuses[:results]

    # Select the services to nest under MyAccountStatus
    my_account_children = services.select do |s|
      %w[FolioPatron IlliadStatus ReshareStatus].include?(s[:name])
    end

    # Determine overall status for MyAccountStatus
    child_statuses = my_account_children.map { |s| s[:status] }

    my_account_status =
      if child_statuses.all? { |s| s == "OK" }
        "OK"
      elsif child_statuses.all? { |s| s != "OK" }
        "ERROR"
      else
        "DEGRADED"
      end

    # Build the MyAccountStatus entry
    my_account_entry = {
      name: "MyAccount Status",
      status: my_account_status,
      message: "",
      children: my_account_children
    }

    # Exclude the nested services from the top-level results
    remaining_services = services.reject do |s|
      %w[FolioPatron IlliadStatus ReshareStatus].include?(s[:name])
    end

    # Add the MyAccountStatus entry to the remaining services
    updated_results = remaining_services + [my_account_entry]

    # Return the updated structure
    {
      results: updated_results,
      status: raw_statuses[:status],
      timestamp: raw_statuses[:timestamp]
    }
  end

  def statuses
    return @statuses if defined? @statuses
    @statuses = StatusPage.check(request: request)
  end

  def authenticate_with_basic_auth
    return true unless StatusPage.config.basic_auth_credentials

    credentials = StatusPage.config.basic_auth_credentials
    authenticate_or_request_with_http_basic do |name, password|
      name == credentials[:username] && password == credentials[:password]
    end
  end
end