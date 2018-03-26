require 'socket'
require 'ipaddr'
#MULTICAST_ADDR = "224.0.0.100"
MULTICAST_ADDR = "ff02::100"
SOURCE_ADDR    = "fd00::1"
#MULTICAST_ADDR = "10.16.160.1"
PORT= 5000
PACKET_SIZE = 1436
10.times do
begin
  socket = UDPSocket.new(Socket::AF_INET6)
  socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
  # cat /sys/class/net/[ifname]/ifindex for index number. Make something smarter
  socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_MULTICAST_IF, [2].pack('i'))
  #socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BINDTODEVICE, "enx00e04c68009e"+'\0')
  start = Time.now
  10000.times do
    socket.send("1" * PACKET_SIZE, 0, MULTICAST_ADDR, PORT)
  end
  ending = Time.now
ensure
  socket.close
end
puts (((10_000 * PACKET_SIZE).to_f / (ending - start)) / 1_000_000.to_f * 8).to_s + " Mb/s"
end
