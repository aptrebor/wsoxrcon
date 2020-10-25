require 'websocket-eventmachine-server'
require 'json'


class ARPServe < WebSocket::EventMachine::Server

  def gen_lo 

    lo_text = %q{Lorem ipsum dolor sit amet 
          consectetur adipiscing elit 
          Pellentesque lacus elit pulvinar 
          id dolor scelerisque dictum vulputate 
          nisi Etiam venenatis lacus ex eget pulvinar 
          dui venenatis ut Fusce et lacus porta 
          vehicula mi eget feugiat leo Suspendisse 
          maximus elementum lorem ut congue}.split

    last = rand (lo_text.length / 2)..lo_text.length
    first = rand 0..(lo_text.length / 2)
    last += (last - first) < 3 ? (rand 3..6) : 0   
    lo_text[first..last].join(" ")
  end


  def gen_user_stuff
    users = ["herbert", "manny", "dirtbag", "cerberus", 
             "gun face", "sticky", "slimeball", "chopper mcgee"]
    rng = rand 8
    [ users[rng], (rand 12345678..87654321).to_s]
  end


  def gpost_pkt
    
    loip = gen_lo
    rnd_user = gen_user_stuff

    gpdata = { Channel: 0,
               Message: gen_lo,
               UserId: rnd_user[1],
               Username: rnd_user[0],
               Color: "#5af",
               Time: Time.now.to_i }
    gpdata = JSON.generate gpdata

    gpost = { Message: gpdata,
              Identifier: -1,
              Type: "Chat",
              Stacktrace: "" }

    JSON.generate gpost
  end
 
end


EM.epoll

EM.run do
 
  conn = nil

  trap("TERM") { stop }
  trap("INT")  { stop }
  
  EventMachine::PeriodicTimer.new(3) do
    puts "--> just text for now"
    if conn 
      puts "--> @@@ connection made"
      conn.send conn.gpost_pkt, :type => "text"
    end
  end

  ARPServe.start(:host => "127.0.0.1", :port => 3120) do |ws|

    conn = ws
    
    ws.onopen do |handshake|
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "   Client connected from: #{handshake.host}"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~"
    end

    ws.onmessage do |msg, type|
      puts "Received message: #{msg}"
      puts "Type: #{type}"
    end

    ws.onclose do
      puts "Client disconnected"
      conn = nil
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

  end

  puts "Server started at port 3120"

  def stop
    puts "Terminating WebSocket Server"
    EventMachine.stop
  end

end
