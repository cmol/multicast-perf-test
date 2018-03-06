require 'socket'
require 'ipaddr'
MULTICAST_ADDR = "225.4.5.6"
LOCAL_ADDR     = "172.16.0.2"
PORT = 5000
#ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(LOCAL_ADDR).hton
sock = UDPSocket.new
sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
sock.bind(LOCAL_ADDR, PORT)
#sock.bind(Socket::INADDR_ANY, PORT)
loop do
  msg, info = sock.recvfrom(1024)
  puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
end

