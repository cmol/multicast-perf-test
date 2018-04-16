require 'socket'
require 'ipaddr'
require 'tty-progressbar'

module McastPerfTest
  class DelayTester
    include McastPerfTest::Helpers
    include McastPerfTest::Constants

    def initialize(options)
      @opts = options
    end

    def run
      state     = nil
      port_send = 7654
      port_recv = 4567
      state     = :send
      unless @opts[:mode] == :send
        state     = :recv
        port_send = 4567
        port_recv = 7654
      end

      # Set-up and prepare sockets
      send_socket = UDPSocket.new(Socket::AF_INET6)
      send_socket.setsockopt(Socket::IPPROTO_IPV6,
                            Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
      send_socket.setsockopt(
        Socket::IPPROTO_IPV6,
        Socket::IPV6_MULTICAST_IF,
        [interface_idx(@opts[:interface])].pack('i')
      )
      recv_socket = UDPSocket.new(Socket::AF_INET6)
      ip     = IPAddr.new(ETH_MULTICAST_ADDR).hton +
                  [interface_idx(@opts[:interface])].pack('i')
      recv_socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, ip)
      recv_socket.bind("::", port_recv)

      send_time    = Time.at(0)
      measurements = []
      # Main loop
      @opts[:runs].times do
        if state == :send
          msg = 0b10101010.chr
          send_socket.send(msg * @opts[:packet_length], 0, ETH_MULTICAST_ADDR,
                           port_send)
          send_time = Time.now
          state = :recv
        else
          msg, info = recv_socket.recvfrom(1500)
          current = Time.now
          unless send_time.to_i == 0
            measurements << current - send_time
          end
          state = :send
        end
      end

      # What was the delay?
      puts measurements.sort[measurements.length / 2]

    end

  end # class
end # module
