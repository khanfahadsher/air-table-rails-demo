require 'net/http'
require 'uri'

namespace :json do

  # Usage: rake json:set_fields[file_name]
  desc "Set some sample fields to an existing JSON file"
  task :read_file, [:file_name] => :environment do |t, args|
    file_name = ARGV.first  #Assigning first pass argument as file name
    fields = get_file_data(file_name)
    p fields
  end

  desc "Write Data in File fields to an existing JSON file"
  task :write_on_file, [:file_name] => :environment do |t, args|
    file_name = ARGV.first || args[:file_name]  #Assigning first pass argument as file name
    # First we've to read data from AirTable and put data on file.
    Airtable.call(file_name: file_name, from: 'rake_task', request_for: "WRITE_FILE")

    p "Data is Imported Successfully."
  end

  def get_file_data(file_name)
    file = get_file(file_name)
    fields = JSON.parse(file)
  end

  def get_file(file_name)
     file_folder  = Rails.root.join('app','assets','sample') 		# Step over the right folder
     file = File.read(file_folder.join(file_name + ".json"))		 	# Get the JSON file
   end


end