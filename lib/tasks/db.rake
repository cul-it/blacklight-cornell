namespace :db do
    desc 'extract fixtures from database'
    task :extract_fixtures => :environment do
      #sql  = 'SELECT * FROM "%s"'
      sql  = 'SELECT * FROM %s'
      skip_tables = ["schema_migrations"]
      ActiveRecord::Base.establish_connection
      if (not ENV['TABLES'])
        tables = ActiveRecord::Base.connection.tables - skip_tables
      else
        tables = ENV['TABLES'].split(/, */)
      end
      if (not ENV['OUTPUT_DIR'])
        output_dir="#{Rails.root}/test/fixtures"
      else
        output_dir = ENV['OUTPUT_DIR'].sub(/\/$/, '')
      end
      (tables).each do |table_name|
        i = "000"
        File.open("#{output_dir}/#{table_name}.yml", 'w') do |file|
          #data = ActiveRecord::Base.connection.select_all(sql % table_name.upcase)
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
          puts "wrote #{table_name} to #{output_dir}/"
        end
      end
    end
end
