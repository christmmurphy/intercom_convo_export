require 'net/http'
require 'uri'
require './env' if File.exists?('env.rb')

uri = URI.parse("https://api.intercom.io/conversations")
request = Net::HTTP::Get.new(uri)
request["Authorization"] = "Bearer #{ENV['access_token']}"
request["Accept"] = "application/json"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

# response.code
p response.body
