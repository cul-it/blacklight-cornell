module ExternalDataHelper
	require 'yaml'
	require 'json'
 	def get_exclusion(key, exclude_entities)
 		return_json = {"exclusion": false}
 		exclusion_key = key.sub(/[.,;]?$/, '')		
 		# Check for key where the ending punctuation has been replaced
 		if(exclude_entities.key?(exclusion_key))
 			return_json[:exclusion] = true
 			if(exclude_entities[exclusion_key]!= nil && exclude_entities[exclusion_key].length)
 				return_json[:properties] = exclude_entities[exclusion_key]
 			end
 		end
 		return return_json
 	end
 
 	def load_yaml()
 		data_file_path = Rails.root.join("public/excludeEntities.yml")
 		exclude_entities = YAML.load(File.read(data_file_path))
 		return exclude_entities
 	end

	#Parameter: query_type, and arguments: auth string or uri
	#Returns "exclusion" true/false for string or uri
	#And list of properties if property excluded FOR that particular uri
	#Not handling removal of entire property for the time being
 	def check_permissions(key)
 		#@query_type = params[:query_type] || ""		
 		return_json = {}
 		if(key != "")
 			exclude_entities = load_yaml()
 			if(!exclude_entities.nil?)
 				return_json = get_exclusion(key, exclude_entities)
 			end 
 		end
 		
 		#render :json => return_json
 		return return_json
 	
 	end
end