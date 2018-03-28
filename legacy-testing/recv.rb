require 'socket'
require 'ipaddr'
MULTICAST_ADDR = "224.0.0.100"
LOCAL_ADDR     = "10.7.10.65"
PORT = 5000
#ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(LOCAL_ADDR).hton
sock = UDPSocket.new
sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, [1].pack("i"))
#sock.bind(LOCAL_ADDR, PORT)
sock.bind(Socket::INADDR_ANY, PORT)
loop do
  msg, info = sock.recvfrom(1500)
#  puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
  printf(".")
end

