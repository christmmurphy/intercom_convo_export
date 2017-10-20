require 'net/http'
require 'uri'
require './env' if File.exists?('env.rb')
require 'json'
require 'intercom'

# create a file to write to
export_start = Time.now.utc
File.open("export.txt", "w") {|f| f.write("CONVERSATION EXPORT: #{export_start}" + "\n"+"\n") }
p "Export Started At: #{export_start}"

# method to write to the export file
def write_to_export(content)
    content = content.to_s
    File.open("export.txt", 'a+') do |f|
      f.puts(content + "\n")
    end
end


# set up Intercom Auth for Ruby Requests
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
  end
end

def parse_convo_to_parts(single_convo)
  export_a = "----------------------------------------------------------------"
  export_b = "CONVO STARTED AT #{single_convo.created_at}"
  first_message = "Body: #{single_convo.conversation_message}"
  # export_c = single_convo.created_at
  export_d = "Body: #{first_message.body}"
  export_e = "Author: #{first_message.author.class}"
  single_convo.conversation_parts.each do |part|
    parse_convo_part(part)
  end
  if single_convo.conversation_parts.last
    export_f = "CONVO ENDED AT #{single_convo.conversation_parts.last.created_at}"
    export_g = "----------------------------------------------------------------" + "\n" + "\n"
  end
  write_to_export(export_a)
  write_to_export(export_b)
  write_to_export(export_c)
  write_to_export(export_d)
  write_to_export(export_e)
  write_to_export(export_f)
  write_to_export(export_g)
end

def parse_convo_part(convo_part)
  # export_h = "CONVO PART"
  export_i = "Created At: #{created_at = convo_part.created_at}"
  export_j = "Message Body: #{body = convo_part.body if convo_part.body}"
  export_k = "Author ID: #{author = convo_part.author.id}"
  #write_to_export(export_h)
  write_to_export(export_i)
  write_to_export(export_j)
  write_to_export(export_k)
end


# parse_convo_to_parts(@intercom.conversations.find(id: 12140987705))


get_single_convos(convo_ids)
# parse_convo_to_parts(get_single_convos(convo_ids))
