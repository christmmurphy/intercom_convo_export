require 'net/http'
require 'uri'
require 'json'
require 'intercom'

class ConversationsParser
  attr_reader :file_name, :token, :intercom

  def initialize(file_name, token)
    @file_name = file_name
    @intercom = Intercom::Client.new(token: token)

    File.write(file_name, "")
  end

  def write_to_file_and_print(content)
    puts content
    File.open(file_name, 'a+') { |f| f.puts(content.to_s + "\n") }
  end

  def find_author(author)
    if author.class == Intercom::Admin
      { name: intercom.admins.find(id: author.id).name, type: "admin" }
    elsif author.class == Intercom::User
      { name: intercom.users.find(id: author.id).name, type: "user" }
    elsif author.class == Intercom::Lead
      { name: intercom.contacts.find(id: author.id).name, type: "lead" }
    else
      { name: "Operator", type: "Bot" }
    end
  rescue Intercom::AttributeNotSetError, Intercom::ResourceNotFound
    { name: nil, type: nil }
  end

  def parse_conversation_parts(conversation)
    write_to_file_and_print("CONVERSATION: #{conversation.id} STARTED AT #{conversation.created_at}")
    first_message = conversation.conversation_message

    write_to_file_and_print(first_message.body)

    author = with_rate_limit { find_author(first_message.author) }
    write_to_file_and_print("name:\n#{author[:name]}\ntype:\n#{author[:type]}")

    conversation.conversation_parts.each do |part|
      parse_conversation_part(part)
    end
  end

  def parse_conversation_part(conversation_part)
    write_to_file_and_print("CONVO PART")
    write_to_file_and_print("created_at: #{conversation_part.created_at}")

    body = conversation_part.body.to_s.gsub(/<\/?[^>]*>/, "")

    write_to_file_and_print("body:\n#{body}")

    author = with_rate_limit { find_author(conversation_part.author) }
    write_to_file_and_print("name:\n#{author[:name]}\ntype:\n#{author[:type]}")

    write_to_file_and_print("attachments:\n#{conversation_part.attachments.to_s}")
  end

  def with_rate_limit
    value = yield

    sleep 10 if intercom.rate_limit_details[:remaining] <= 30

    value
  end

  def get_single_conversation(id)
    with_rate_limit do
      intercom.conversations.find(id: id)
    end
  end

  def parse(id)
    conversation = get_single_conversation(id)
    parse_conversation_parts(conversation)
  end
end

class IntercomConversationsExporter
  attr_reader :token

  def initialize
    @token = ENV["INTERCOM_TOKEN"]
  end

  def get_intercom_conversations_number_of_pages(token)
    uri = URI.parse("https://api.intercom.io/conversations")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/json"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    JSON.parse(response.body)["pages"]["total_pages"]
  end

  def get_intercom_conversations_page(number, token)
    uri = URI.parse("https://api.intercom.io/conversations?per_page=20&page=#{number}")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/json"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end


  def process_conversations(file_name, conversations)
    conversations.each do |conversation|
      ConversationsParser.new(file_name, token).parse(conversation["id"])
    end
  end

  def download(page)
    pages = get_intercom_conversations_number_of_pages(token)
    until page == pages
      conversations_page = get_intercom_conversations_page(page, token)
      
      puts "downloading page: #{page}"
      File.write("convo_exporter_#{page}.json", conversations_page["conversations"].to_json)
      page = conversations_page["pages"]["page"]
    end
  end

  def parse(page)
    Dir.glob("convo_exporter_*").each do |name|
      f_page = name.split('_').last.split('.').first.to_i
      next if f_page < page
      
      puts "parsing page: #{page}"
      convo = JSON.parse(File.read("convo_exporter_#{page}.json"))
      process_conversations("convo_exporter_parsed_#{page}.txt", convo)
    end
  end
end

command = ARGV[0]
opt = ARGV[2].to_i
IntercomConversationsExporter.new.download(opt) if command == "download"
IntercomConversationsExporter.new.parse(opt) if command == "parse"

# ruby app.rb download 1
# ruby app.rb parse 1
