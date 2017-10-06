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

# all_convos needs to be an array of conversation id's that we got from the call above 👆

def get_single_convos(convo_ids)
	convo_ids.each do |id|
	  single_convo = @intercom.conversations.find(id: id)
	  # p single_convo.conversation_parts
    parse_convo_to_parts(single_convo)
    rate_limiter
  end
end

def parse_convo_to_parts(single_convo)
  p "🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷🎷"
  p "CONVO STARTED AT #{single_convo.created_at}"
  first_message = single_convo.conversation_message
  p single_convo.created_at
  p first_message.body
  p first_message.author
  single_convo.conversation_parts.each do |part|
    parse_convo_part(part)
  end
  if single_convo.conversation_parts.last
    p "CONVO ENDED AT #{single_convo.conversation_parts.last.created_at}"
    p "🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄🏄"
  end
end

def parse_convo_part(convo_part)
  p "CONVO PART"
  p created_at = convo_part.created_at
  p body = convo_part.body if convo_part.body
  p author = convo_part.author.id
end

def rate_limiter
  @remaining = @intercom.rate_limit_details[:remaining]
  @threshold = 30
  @sleep_time = 10
  #Check the remaining limit against the threshold
  if @remaining <= @threshold
    sleep(@sleep_time)
  end
end


# parse_convo_to_parts(@intercom.conversations.find(id: 12140987705))


get_single_convos(convo_ids)
# parse_convo_to_parts(get_single_convos(convo_ids))
