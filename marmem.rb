require 'rubygems'
#require 'em/pure_ruby'
require 'websocket-eventmachine-client'
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

class ARPClient < WebSocket::EventMachine::Client
  attr_accessor :state

  def self.connect_with_block args
    ws_conn = connect args
    args[:block].call ws_conn
  end
end

conn = nil

EM.epoll
EM.run do

  trap("TERM") { stop }
  trap("INT")  { stop }


  ws_blk = Proc.new { |ws|

    conn = ws

    ws.onopen do
      puts "** onopen says: Connected!"
      ws.send "Hello"
    end

    ws.onmessage do |msg, type|

      server_msg = JSON.parse(msg)

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

    ws.onclose do
      puts "Disconnected -- stopping EM"
      ws.close
    end

    ws.onerror do |e|
      puts "Error: #{e}"
    end

    ws.onping do |msg|
      puts "Received ping: #{msg}"
    end

    ws.onpong do |msg|
      puts "Received pong: #{msg}"
    end
  }


  EventMachine::PeriodicTimer.new(3) do
    puts "*** timer!"

    if conn.state == :closed
      puts "connection closed"
      # ws.reconnect "192.168.1.69", 3120
      # ws = ARPClient.connect(:uri => "ws://192.168.1.69:3120")
      make_connection ws_blk
    else
      puts "still connected"
    end
  end


  def make_connection blk
    ARPClient.connect_with_block(:uri => "ws://192.168.1.69:3120", :block => blk)
  end

  make_connection ws_blk

  def stop
    puts "Terminating connection"
    EventMachine.stop
  end

end