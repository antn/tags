require 'sinatra'
require 'erubis'
require 'httparty'
require 'better_errors'
require 'binding_of_caller'
set :erb, :escape_html => true

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

get '/' do
  if params[:service_tag]
    @device = ServiceTag.new(params[:service_tag])
    if @device.valid_response?
      erb :index
    else
      erb :error
    end
  else
    erb :index
  end
end

def warranty_icon(enddate)
  Time.parse(enddate) > Time.now ? "octicon-check active" : "octicon-x expired"
end

class ServiceTag
  include HTTParty
  def initialize(service_tag)
    @service_tag = service_tag
    initialize_api
  end

  def initialize_api
    @request = HTTParty.get("https://api.dell.com/support/v2/assetinfo/warranty/tags.json?svctags=#{@service_tag}&apikey=d676cf6e1e0ceb8fd14e8cb69acd812d")
    @api_data = JSON.parse(@request.body)
  end

  def valid_response?
    @request.success? && @api_data["GetAssetWarrantyResponse"]["GetAssetWarrantyResult"]["Faults"].nil?
  end

  def description
    @api_data["GetAssetWarrantyResponse"]["GetAssetWarrantyResult"]["Response"]["DellAsset"]["MachineDescription"]
  end

  def ship_date
    Time.parse(@api_data["GetAssetWarrantyResponse"]["GetAssetWarrantyResult"]["Response"]["DellAsset"]["ShipDate"]).strftime("%B %e, %Y")
  end

  def warranties
    @api_data["GetAssetWarrantyResponse"]["GetAssetWarrantyResult"]["Response"]["DellAsset"]["Warranties"]["Warranty"]
  end

  def errors
    @api_data["GetAssetWarrantyResponse"]["GetAssetWarrantyResult"]["Faults"]["FaultException"]["Message"]
  end
end
