require 'socket'
require 'ipaddr'
#MULTICAST_ADDR = "225.4.5.6"
MULTICAST_ADDR = "224.0.0.22"
SOURCE_ADDR    = "172.16.0.1"
#MULTICAST_ADDR = "10.16.160.1"
PORT= 5000
10.times do
begin
  socket = UDPSocket.open
  socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, [1].pack('i'))
  socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_IF, IPAddr.new(SOURCE_ADDR).hton)
#  socket.bind("172.16.0.1", 0)
  #socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BINDTODEVICE, "enp0s25"+'\0')
  start = Time.now
  10000.times do
    socket.send("MAXMULTICASTMT" * 100, 0, MULTICAST_ADDR, PORT)
  end
  ending = Time.now
ensure
  socket.close
end
puts (((10_000 * 1400).to_f / (ending - start)) / 1_000_000.to_f * 8).to_s + " Mb/s"
end
