require 'rest-client'
require 'json'
require 'yaml'
require 'time_ago_in_words'
require 'terminal-table'
require 'highline'
require 'colorize'
require 'readline'
#require 'websocket-eventmachine-client'
require 'kontena-websocket-client'
require 'open-uri'

class Time

  alias_method :ago_in_words_no_timezone, :ago_in_words

end

class Presbeus

  attr_accessor :default_device

  def initialize_arguments
    argument(:help, [], "show this help")  { help }
    argument(:realtime, [], "handle realtime event stream")  { realtime }
    argument(:realtime_raw, [], "handle realtime event stream")  { @client = false; realtime }
    argument(:shell, [], "run in an interactive shell") { shell }
    argument(:devices, [], "list devices") { puts table devices }
    argument(:pushes, [], "list pushes") { puts table pushes_with_color }
    argument(:threads, [:device_id], "show threads for device") do
      |c| puts table threads c[0] 
    end
    argument(:last, [:device_id], "show last thread for device") do |c|
      puts table last_thread c[0]
    end
    argument(:push, [:all], "push note to all devices") do |c|
      push c.join(" ")
    end
    argument(:thread, [:device_id, :thead_id], "show SMS thread") do |c|
      puts table thread_with_two_columns_wrap c[0], c[1]
    end
    argument(:sms, [:device_id, :phone_number, :all], "send SMS") do |c| 
      send_sms c[0], c[1], c[2..-1].join(" ")
    end
  end

  def initialize client = true
    @client = client
    initialize_arguments
    configuration_path = "#{ENV['HOME']}/.config/presbeus.yml"
    configuration = YAML.load_file configuration_path
    api_server = 'https://api.pushbullet.com'
    api_server = configuration["api_server"] if configuration.include? "api_server"
    @default_device = configuration["default_device"] if configuration.include? "default_device"
    @token = `#{configuration['password_command']}`.chomp
    @notify_command = configuration['notify_command']
    @headers = {"Access-Token" => @token, "Content-Type" => "json"}
    @api_prefix = api_server + '/v2/'
  end

  def realtime_no_reconnect
    uri = "wss://stream.pushbullet.com/websocket/#{@token}"
    Kontena::Websocket::Client.connect(uri, ping_timeout: 60) do |client|
      client.on_pong do |time, delay|
        p time, delay
      end
      client.read do |message|
        json = JSON.parse(message)
        type = json["type"]
        if type != "nop"
          if @client
            if type == "tickle"
              puts(table(pushes_with_color(Time.now.to_i) do |push|
                `#{@notify_command} "#{push[1]}"` if @notify_command
              end))
            end
          else
            puts message
          end
        else
          client.send message # pong
        end
      end
    end
  end

  def realtime
    $stdout.sync = true if !@cient
    while true
      begin
        realtime_no_reconnect
      rescue Kontena::Websocket::TimeoutError => e
        puts "timeout #{e}" if @client
      rescue Kontena::Websocket::ConnectError => e
        puts "connect error #{e}" if @client
        sleep 60
      end
    end
  end

  def post_v2 what, payload
    args = {url: @api_prefix + what, payload: payload.to_json, headers: @headers}
    if @client
      RestClient.post(args[:url], args[:payload], args[:headers])
    else
      args
    end
  end

  def get_v2 what
    args = {url: @api_prefix + what, headers: @headers}
    if @client
      response = RestClient.get(args[:url], args[:headers])
      JSON.parse response.body
    else
      args
    end
  end

  def devices
    get_v2("devices")["devices"].map do |device|
      [device["iden"], device["model"]]
    end
  end

  def self.parse_thread thread
    [thread["id"]] + thread["recipients"].map { |r| [r["address"], r["name"]] }.flatten
  end

  def threads iden
    get_v2("permanents/#{iden}_threads")["threads"].reverse.map do |thread|
      parse_thread thread
    end
  end

  def thread device, id
    get_v2("permanents/#{device}_thread_#{id}")["thread"]
  end

  def pushes modified_after = nil
    path = "pushes"
    path += "?modified_after=#{modified_after}" if modified_after
    get_v2(path)["pushes"].map do |push|
      [Time.at(push["created"].to_i).ago_in_words, push["body"]]
    end
  end

  def user_iden
    get_v2("users/me")["iden"]
  end

  def push message
    post_v2 "pushes", {
      title: "push from presbeus",
      type: "note",
      body: message,
    }
  end

  def send_sms device, conversation_iden, message
    post_v2 "ephemerals", {
      push: {
        conversation_iden: conversation_iden,
        message: message,
        package_name: "com.pushbullet.android",
        source_user_iden: user_iden,
        target_device_iden: device,
        type: "messaging_extension_reply"
      },
      type: "push"
    }
  end

  def table rows, config = {}
    t = Terminal::Table.new config.merge({:rows => rows})
    t.style = { border_top: false, border_bottom: false, border_y: '' }
    t
  end

  def wrap s, width
    s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
  end

  def with_color string, width, background
    lines = string.split("\n")
    lines.map { |line| line.ljust(width).colorize(color: :black, background: background)}.join "\n"
  end

  def width
    HighLine::SystemExtensions.terminal_size[0]
  end

  def half_width
    width / 2 - 4
  end

  def width_2
    width - 4
  end

  def thread_with_two_columns_wrap device, id
    res = []
    thread(device, id).reverse.each do |message|
        text = [wrap(message["body"], half_width), ""]
        date = ["\n#{Time.at(message["timestamp"]).ago_in_words}", ""]
        if message["direction"] != "incoming"
          text[0] = with_color text[0], half_width, :white
          text.reverse!
          date.reverse!
        else
          text[0] = with_color text[0], half_width, :green
        end
        res << date
        res << text
    end
    res 
  end

  def pushes_with_color modified_after = nil
    pushes(modified_after).reverse.map do |push|
      yield(push) if block_given?
      ["\n" + push[0] + "\n" + with_color(wrap(push[1], width_2), width_2, :green)]
    end
  end

  def last_thread device
     thread_with_two_columns_wrap device, threads(device).last[0]
  end

  def argument name, args, description
    @arguments ||= {}
    @arguments[name] = {args: args, description: description, block: Proc.new { |c| yield c } }
  end

  def help
    a = @arguments.to_a.map do |_|
       [_[0].to_s, _[1][:args].map { |x| x.to_s }.join(" "), _[1][:description]]
    end
    puts table a
  end

  def shell
    while buf = Readline.readline("> ", true)
      run buf.split
    end
  end

  def good_syntax? name, command
    args = @arguments[name][:args]
    count = args.size + 1
    args.include?(:all) ? command.size >= count : command.size == count
  end

  def run command
    if command.size > 0 
      name = command[0].to_sym
      if @arguments.keys.include?(name) and good_syntax?(name, command)
        @arguments[name][:block].call command[1..-1]
        return
      end
    end
    help
  end

end


