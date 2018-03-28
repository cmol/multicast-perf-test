require 'socket'
require 'ipaddr'

module McastPerfTest
  class Sender
    include McastPerfTest::Helpers
    include McastPerfTest::Constants

    def initialize(options)
      # Find sending interval and number of sends
      @interval = 1.0 / (options[:bitrate].to_f / options[:pkg_length].to_f)
      @num_sends = TEST_TIME / @interval
      @pkg_length = options[:pkg_byte_size] / 4

      # Set-up and prepare sockets
      @eth_socket = UDPSocket.new(Socket::AF_INET6)
      @eth_socket.setsockopt(Socket::IPPROTO_IPV6,
                            Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
      @eth_socket.setsockopt(
        Socket::IPPROTO_IPV6,
        Socket::IPV6_MULTICAST_IF,
        [interface_index(options[:ethernet])].pack('i')
      )

      @wifi_socket = UDPSocket.new(Socket::AF_INET6)
      @wifi_socket.setsockopt(Socket::IPPROTO_IPV6,
                             Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
      @wifi_socket.setsockopt(
        Socket::IPPROTO_IPV6,
        Socket::IPV6_MULTICAST_IF,
        [interface_index(options[:wifi])].pack('i')
      )
    end

    def run
      # Begin sending loop
      (0...@num_sends.to_i).each do | idx |
        next_round = Time.now + @interval
        # Make the index into a 32-bit unsigned int, network byte order
        msg = [idx].pack("I>")
        @wifi_socket.send(msg * @pkg_length, 0, WIFI_MULTICAST_ADDR, WIFI_PORT)
        @eth_socket.send(msg * @pkg_length, 0, ETH_MULTICAST_ADDR, WIFI_PORT)
        sleep(next_round - Time.now)
      end
    end

  end # class
end # module
