# -*- encoding : utf-8 -*-
# Exclude particular properties or URIs from display
class HandleExternalDataController < ApplicationController
	require 'yaml'
	require 'json'

	#Is this URI allowed
	#def get_uri_exclusion(uri, exclude_URI)
	#	return {"exclusion":false}
	#end
	#Is this property allowed - OR a list of properties
	#def property_allowed(property, exclude_property)
	#	return {"exclusion":false}
	#end
	#Is this property allowed for this URI
 	#def prop_for_uri_allowed(uri, property, exclude_property_for_URI)
 	#	return true
 	#end

 	#String or URI allowed (in case heading itself is not matching)
 	def get_exclusion(key, exclude_entities)
 		return_json = {"exclusion": false}
 		if(exclude_entities.key?(key))
 			return_json["exclusion"] = true
 			if(exclude_entities[key]!= nil && exclude_entities[key].length)
 				return_json["properties"] = exclude_entities[key]
 			end
 		end
 		return return_json
 	end

 	def load_yaml()
 		data_file_path = Rails.root.join("public/excludeEntities.yml")
 		begin
			exclude_entities = YAML.load(File.read(data_file_path), aliases: true)
		rescue
 			exclude_entities = YAML.load(File.read(data_file_path))
		end
 		return exclude_entities
 	end

	#Parameter: query_type, and arguments: auth string or uri
	#Returns "exclusion" true/false for string or uri
	#And list of properties if property excluded FOR that particular uri
	#Not handling removal of entire property for the time being
 	def check_permissions
 		#@query_type = params[:query_type] || ""
 		@key = params[:key] || ""

 		exclude_entities = load_yaml()

 		return_json = {}
 		if(@key != "")
 			return_json = get_exclusion(@key, exclude_entities)
 		end

 		render :json => return_json

 	end



end