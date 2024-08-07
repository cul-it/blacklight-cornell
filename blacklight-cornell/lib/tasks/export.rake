namespace :export do
  desc "Prints Location.all in a seeds.rb way."
  task :seeds_format => :environment do
   Location.order(:id).all.each do |country|
      puts "Location.create(#{country.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include?(key)}.to_s.gsub(/[{}]/,'')})"
    end
  end
end
