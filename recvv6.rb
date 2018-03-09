require 'socket'
require 'ipaddr'
MULTICAST_ADDR = "ff22::100"
LOCAL_ADDR     = "fd00::2"
PORT = 5000
#ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
ip =  IPAddr.new(MULTICAST_ADDR).hton + [2].pack('i')
sock = UDPSocket.new(Socket::AF_INET6)
sock.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, ip)
#sock.bind(LOCAL_ADDR, PORT)
sock.bind(LOCAL_ADDR, PORT)
loop do
  msg, info = sock.recvfrom(1500)
#  puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
  printf(".")
end

