require 'net/http'
require 'uri'
require './env' if File.exists?('env.rb')
require 'json'
require 'intercom'

# create a .txt file to write to
export_start = Time.now.utc
File.open("export.txt", "w") {|f| f.write("Conversation Export: #{export_start}\n\n") }
p "Export Started At: #{export_start} \n"

# method to write to the export file
def write_to_export(content)
    content = content.to_s
    File.open("export.txt", 'a+') do |f|
      f.puts(content + "\n")
    end
end

#set up Intercom client for ruby requests
@intercom = Intercom::Client.new(token: ENV['access_token'])

#set up CURL client for grabbing conversations
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
  find_author(first_message.author)
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
  body = convo_part.body
  p body.gsub(/<\/?[^>]*>/, "") unless body.nil?
  author = convo_part.author
  find_author(author)
  p attachment = convo_part.attachments unless convo_part.attachments.empty?
end

def find_author(author)
  author_type = author.class
  if author_type == Intercom::Admin
    author_type = "Admin"
    found_author = @intercom.admins.find(id: author.id)
    name = found_author.name
  elsif author_type == Intercom::User
    author_type = "User"
    found_author = @intercom.users.find(id: author.id)
    name = found_author.name
  elsif author_type == Intercom::Lead
    author_type = "Lead"
    found_author = @intercom.contacts.find(id: author.id)
    lead_identifier(found_author)
  else
    author_type = "Bot"
    found_author = "Operator"
  end
  p author_type
  p found_author if name.nil?
  p name unless name.nil?
end

def lead_identifier(lead_author)
  if lead_author.email
    name = "Email: #{lead_author.email}"
  elsif lead_author.name
    name = "Name: #{lead_author.name}"
  else
    name = lead_author.pseudonym
  end
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

get_single_convos(convo_ids)
# parse_convo_to_parts(get_single_convos(convo_ids))
