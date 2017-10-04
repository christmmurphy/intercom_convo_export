require 'net/http'
require 'uri'
require './env' if File.exists?('env.rb')
require 'json'
require 'intercom'

@intercom = Intercom::Client.new(token: ENV['access_token'])

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
response.body

# parsing the JSON response from a list of conversations
parsed_convo_list = JSON.parse(response.body)

convo_ids= []

parsed_convo_list['conversations'].each do |convo|
  convo_ids << convo['id'].to_i
end

convo_ids

# all_convos needs to be an array of conversation id's that we got from the call above 👆

def get_single_convos(all_convos)
	all_convos.each do |id|
	  single_convo = @intercom.conversations.find(id: id)
	  p single_convo.admin
  end
end

get_single_convos(convo_ids)
