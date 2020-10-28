#!/home/andrew/.rbenv/shims ruby

# 1602802206

require 'rubygems'
require 'websocket-client-simple'
require 'json'
require 'date'


def parse_date datet
  dt = Time.at(datet).to_datetime
  dt.strftime("%m-%d-%Y %I:%M:%S%P")
end


def rcon_send wskt, command
  
  rng = rand(200)
  puts " Identifier: #{rng}"

  msg = { :Identifier => rng,
          :Message => command,
          :Name => "WebRcon" }.to_json
  wskt.send msg
end


def chat_message js_data

  parsy = JSON.parse(js_data)
  puts "    Channel: #{parsy["Channel"]}"
  puts "    Time:    #{parse_date parsy["Time"]}" 
  puts "    Player:  #{parsy["Username"]}"
  puts "    UserID:  #{parsy["UserId"]}"
  puts "    Msg:     #{parsy["Message"]}"
  puts "-----------------------------------"
end

puts "websocket-client-simple v#{WebSocket::Client::Simple::VERSION}"

ws = WebSocket::Client::Simple.connect 'ws://192.168.1.69:3120'



ws.on :message do |msg|

  server_msg = JSON.parse(msg.data)

  puts "==================="
  puts " Message type: #{server_msg["Type"]}  [#{server_msg["Identifier"]}]"
  puts "-----------------------------------"

  if server_msg["Identifier"] == -1
    chat_message server_msg["Message"]
  else
    puts "#{server_msg["Message"]}"
    puts "-----------------------------------"
  end
end

ws.on :open do

  puts "  --> opened"

  ws.send 'hello!!!'
end

ws.on :close do |e|
  puts "  --> closing"
  p e
  exit 1
end

ws.on :error do |e|
  puts "  --> ** error! **"
  p e
end



loop do
  rcon_send ws, STDIN.gets.strip
end


