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

# all_convos needs to be an array of conversation id's that we got from the call above 👆

def get_single_convos(all_convos)
	all_convos.each do |convo|
	  single_convo = intercom.conversations.find(id: "#{convo.id}")
	  p single_convo
  end
end
