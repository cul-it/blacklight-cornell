class StatusController < ActionController::Base
  before_action :authenticate_with_basic_auth

  # Define parent services and their children here
  NESTED_SERVICES = {
    "MyAccount Status" => %w[FolioPatron IlliadStatus ReshareStatus],
    "Solr Status" => %w[CatalogSolr RepositoriesSolr],
    "Data Status" => %w[Database Cache],
  }.freeze

  def index
    @statuses = nested_statuses
    respond_to do |format|
      format.html
      format.json { render json: @statuses }
      format.xml  { render xml: @statuses }
    end
  end

  private

  # Process and nest services dynamically based on NESTED_SERVICES config
  def nested_statuses
    raw_statuses = statuses
    services = raw_statuses[:results]

    # Duplicate services array to avoid mutating the original
    remaining_services = services.dup

    # Build nested service entries
    nested_entries = NESTED_SERVICES.map do |parent_name, child_service_names|
      # Select child services for this parent
      child_services = remaining_services.select { |s| child_service_names.include?(s[:name]) }
      # Remove selected children from remaining_services
      remaining_services.reject! { |s| child_service_names.include?(s[:name]) }
      # Determine the overall status for the parent
      parent_status = determine_overall_status(child_services.map { |s| s[:status] })

      {
        name: parent_name,
        status: parent_status,
        message: "",
        children: child_services
      }
    end

    # Combine remaining services with the nested parent entries
    updated_results = remaining_services + nested_entries
    # Return the updated structure
    {
      results: updated_results,
      status: raw_statuses[:status],
      timestamp: raw_statuses[:timestamp]
    }
  end

  # Determines overall status based on child statuses
  def determine_overall_status(statuses)
    if statuses.all? { |s| s == "OK" }
      "OK"
    elsif statuses.all? { |s| s != "OK" }
      "ERROR"
    else
      "DEGRADED"
    end
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