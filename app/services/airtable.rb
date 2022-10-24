require 'net/http'
require 'uri'
require 'json'
class Airtable < ApplicationService
  def initialize(*args)
    args = args.first
    @file_name = args[:file_name]
    @request_for = args[:request_for]
    @record_id = args[:record_id]
  end

  def call
    # To Write data on JSON file.
    case @request_for
    when "WRITE_FILE"
      write_file
    when "CREATE_RECORD"
      create_new_record_on_airtable
    when "DELETE_RECORD"
      delete_record_on_airtable
    when "UPDATE_RECORD"
      update_record_on_airtable
    end
  end

  private

  def write_file
    url = ENV['AIRTABLE_COPY_URL']
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    response_data =  response.body
    data = JSON.parse(response_data)
    preserve_updated_records(data)
    write_on_file(@file_name, data.to_h)
    return {status: "Successfully Done", error: nil}
  rescue ActiveRecord::RecordNotUnique => e
    # handle duplicate entry
  end

  def write_on_file(file_name, data)
    file_folder  = Rails.root.join('app','assets','sample')
    File.open(file_folder.join(file_name + ".json"), "w") do |f|   # Open the file to write
      f.puts JSON.pretty_generate(data)                              # Write the updated JSON
    end
  end

  def preserve_updated_records(data)
    new_data =  format_data(data)
    cached_data = CopyCache.detailed_list
    cached_records = cached_data[:records]
    # new_data[:records].try(:keys) -  cached_records[:records].try(:keys)
    new_data[:records].try(:keys).each do |key|
      if cached_records[key].present?
        old_field = new_data[:records][key]["fields"]
        new_field = cached_records[key]["fields"]
        if old_field["Key"] != new_field["Key"] || old_field["Copy"] != new_field["Copy"]
          p "NEW Record >>>>>> KEY:  #{key}"
          cached_data[:updated_data][key] = new_data[:records][key].merge({"updated_at" => DateTime.now.in_time_zone.to_s} )
        end
      else
        p "NEW Record >>>>>> KEY:  #{key}"
        cached_data[:updated_data][key] = new_data[:records][key].merge({"updated_at" => DateTime.now.in_time_zone.to_s} )
      end
    end
    write_on_file("latest_copy", cached_data[:updated_data]) if cached_data[:updated_data].present?
  end

  def format_data(data)
    updated_data = {records: {}}
    data["records"].each do |field|
      updated_data[:records][field["id"]] = field
    end
    updated_data
  end

  def create_new_record_on_airtable
    uri = URI(ENV['AIRTABLE_CREATE_NEW_RECORD'])
    req = Net::HTTP::Post.new(uri)
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{ENV['API_KEY']}"

    # The object won't be serialized exactly like this
    # req.body = "{\n  \"fields\": {\n    \"Key\": \"time\",\n    \"Copy\": \"It is {time, datetime}\"\n  }\n}"
    req.body = {
      'fields' => {
        'Key' => 'time',
        'Copy' => 'It is {time, datetime}'
      }
    }.to_json

    req_options = {
      use_ssl: uri.scheme == "https"
    }
    res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(req)
    end
  end

  def delete_record_on_airtable
    if @record_id.present?
      uri = URI("#{ENV['AIRTABLE_DELETE_RECORD']}/#{@record_id}")
      req = Net::HTTP::Delete.new(uri)
      req['Authorization'] = "Bearer #{ENV['API_KEY']}"

      req_options = {
        use_ssl: uri.scheme == "https"
      }
      res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end
    else
      {error: "Record ID not found!!!"}
    end
  end

  def update_record_on_airtable
    if @record_id.present?
      uri = URI("#{ENV['AIRTABLE_UPDATE_RECORD']}/#{@record_id}")
      req = Net::HTTP::Patch.new(uri)
      req.content_type = 'application/json'
      req['Authorization'] = "Bearer #{ENV['API_KEY']}"

      # The object won't be serialized exactly like this
      # req.body = "{\n  \"fields\": {\n    \"Key\": \"welcome\",\n    \"Copy\": \"Hi {name}, welcome to {app}!\"\n  }\n}"
      req.body = {
        'fields' => {
          'Key' => 'welcome',
          'Copy' => 'Hi Ms/Mrs {name}, welcome to {app}!'
        }
      }.to_json

      req_options = {
        use_ssl: uri.scheme == "https"
      }
      res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end
    else
      {error: "Record ID not found!!!"}
    end
  end

end