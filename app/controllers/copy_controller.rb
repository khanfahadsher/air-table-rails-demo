require 'metaxa'

class CopyController < ApplicationController
  include Metaxa

  before_action :update_kind, :set_kind , only: %[show]

  def index
    # Copy.all(paginate: false)
    # Copy.all(sort: { "Key" => "desc" }, paginate: false)
    if params[:since].present?
      since = convert_epoch(params[:since])
      p "Since is : #{since.in_time_zone}"
      data = CopyCache.latest_records_detailed_list.try(:values)
      if data.present?
        data.select!{ |copy| copy["updated_at"].to_datetime.in_time_zone > since.in_time_zone }
        @copies = data.inject({}) do |result, element|
          result[element["fields"]["Key"]] = element["fields"]["Copy"]
          result
        end
      end
    else
      @copies = CopyCache.list
    end
    respond_to do |format|
      format.html {
        flash[:notice] = "Successfully."
      } unless params[:from_api]
      format.json { render json: {copies: @copies},plain: "OK",status: 200} if params[:from_api]
    end
  end

  def show
    if @copy.present?
      set_local_from_params(params)
      render json: {  value: get_copy_value(@copy) }, status: 200
    else
      render json: {  value: '' }, status: 200
    end
  end

  def bye
    render json: {  value: 'Goodbye' }, status: 200
  end

  def refresh
    unless copy_keys.include?("time")
      # Create New Record on Airtable
      Airtable.call(file_name: "copy", from: 'rake_task', request_for: "CREATE_RECORD")
    end
    # Service to Load Data from Airtable and write on JSON file
    Airtable.call(file_name: "copy", from: 'rake_task', request_for: "WRITE_FILE")
    # Refresh Server Data
    CopyCache.refresh_cache
    time = " #{DateTime.now.strftime("%b %a %d %I:%M:%S %p")}"
    render json: {  value: "It is #{time}"}, status: 200
  end

  private

  def get_copy_value(copy)
    copy = copy.gsub("{","\#{")
    instance_eval copy.inspect.gsub('\\', '')
  end

  def set_local_from_params(params)
    params.keys.each{|i| introduce i.to_sym, with_value: params[i]}
  end

  def copy_keys
    CopyCache.list.try(:keys) || []
  end

  def update_kind
    if params["format"].present? && ["created_at","updated_at"].include?(params["format"])
      get_datetime_format(params[params["format"]],params["format"])
    elsif ["time"].include?(params["kind"])
      get_datetime_format(params["time"],"time")
    end

    if params["kind"].present? && params["format"].present?
      params["kind"] += ".#{params["format"]}"
    end

  end

  def set_kind
    copies = CopyCache.list
    @copy = copies[params["kind"]]
    if @copy.present? && (params["format"].present? || ["time"].include?(params["kind"]))
      @copy.gsub!("datetime", '')
      @copy.gsub!(",", '')
    end
  end

  def get_datetime_format(element,params_key)

    date = convert_epoch(element).strftime("%b %a %d %I:%M:%S %p")
    params[params_key] = date
  end

  def convert_epoch(element)
    # https://www.epochconverter.com/
    t = Time.at(element.try(:to_i))
    date = t.to_datetime
  end

end
