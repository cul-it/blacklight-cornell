class MyAccountService < StatusPage::Services::Base
  def check!
    errors = []

    [FolioPatron, IlliadTransactions, ReshareStatus].each do |service_class|
      service = service_class.new

      begin
        service.check!
      rescue StandardError => e
        errors << { service: service_class.name, error: e.message }
      end
    end

    raise "MyAccount has issues: #{errors.map { |e| "#{e[:service]} - #{e[:error]}" }.join(', ')}" unless errors.empty?
  end

  def detailed_status
    [FolioPatron, IlliadTransactions, ReshareStatus].map do |service_class|
      service = service_class.new

      begin
        service.check!
        { name: service_class.name, status: 'OK' }
      rescue StandardError => e
        { name: service_class.name, status: "Error: #{e.message}" }
      end
    end
  end
end
