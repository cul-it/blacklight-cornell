module Status
  class ProcessorService
    # Define parent services and their children here
    NESTED_SERVICES = {
      "Data Status" => %w[Database Cache],
      "MyAccount Status" => %w[FolioPatronStatus IlliadStatus ReshareStatus],
      "Solr Status" => %w[CatalogSolrStatus RepositoriesSolrStatus],
      "Request Status" => %w[FolioPatronStatus IlliadStatus FolioRequestStatus ] #todo =>  need to create additional service checks for Requests
    }.freeze

    def initialize(request)
      @request = request
    end

    # Main method to process and return nested statuses
    def process
      raw_statuses = fetch_statuses
      services = raw_statuses[:results]

      # Build a lookup hash for quick access to services by name
      services_lookup = services.each_with_object({}) do |service, hash|
        hash[service[:name]] = service
      end

      # Track services that have been nested to avoid duplicate top-level entries
      nested_service_names = Set.new

      # Build nested service entries
      nested_entries = NESTED_SERVICES.map do |parent_name, child_service_names|
        # Select child services for this parent using the lookup
        child_services = child_service_names.map { |name| services_lookup[name] }.compact

        # Mark these services as nested
        nested_service_names.merge(child_service_names)

        # Determine the overall status for the parent
        parent_status = determine_overall_status(child_services.map { |s| s[:status] })

        {
          name: parent_name,
          status: parent_status,
          message: "",
          children: child_services
        }
      end

      # Include services that are not nested under any parent as top-level entries
      remaining_services = services.reject { |s| nested_service_names.include?(s[:name]) }

      # Combine remaining services with the nested parent entries
      updated_results = remaining_services + nested_entries

      # Return the updated structure
      {
        results: updated_results,
        status: raw_statuses[:status],
        timestamp: raw_statuses[:timestamp]
      }
    end

    private

    # Fetch raw statuses using StatusPage
    def fetch_statuses
      StatusPage.check(request: @request)
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
  end
end