class CopyCache
  @@copies = {}
  @@detailed_latest_copies = {}
  @@detailed_copies = {
    updated_data: {},
    created_at: DateTime.now.in_time_zone,
    updated_at: DateTime.now.in_time_zone,
    "records": {}
  }

  class << self
    # To store & retrieve data From Cache Constant
    def refresh_cache
      temp_copies = read_json_file("copy")
      # @@detailed_copies[:created_at] = DateTime.now    # To Set time when the Cache was created
      # Put all the Fields in Cache
      if temp_copies.present? && temp_copies["records"].present?
        # @@detailed_copies["records"] ={}
        temp_copies["records"].each do |field|
          @@detailed_copies[:records][field["id"]] = field.merge({"updated_at" => DateTime.now.in_time_zone.to_s} )
        end
      end
      p @@detailed_copies

      temp_latest_copies = read_json_file("latest_copy")
      if temp_latest_copies.present?
        temp_latest_copies.each do |field|
          @@detailed_latest_copies[field.first] = field.second
        end
      end
      p @@detailed_latest_copies

    end
    # To retrieve data From Cache Constant
    def list
      copies_list = @@detailed_copies[:records].values.inject({}) do |result, element|
        result[element["fields"]["Key"]] = element["fields"]["Copy"]
        result
      end
      @@copies.merge( copies_list )
    end

    def detailed_list
      @@detailed_copies || {}
    end

    def latest_records_detailed_list
      @@detailed_latest_copies
    end

    def latest_records_list
      copies_list = @@detailed_latest_copies.values.inject({}) do |result, element|
        result[element["fields"]["Key"]] = element["fields"]["Copy"]
        result
      end
      copies_list || {}
    end

    # To READ data From JSON File
    def read_json_file(file_name)
      file_folder  = Rails.root.join('app','assets','sample') 		# Step over the right folder
      file = File.read(file_folder.join(file_name + ".json"))		 	# Get the JSON file
      temp_copies = JSON.parse(file)
    end
  end
end

CopyCache.refresh_cache


