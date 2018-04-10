require 'socket'
require 'ipaddr'
require 'tty-progressbar'

module McastPerfTest
  class Sender
    include McastPerfTest::Helpers
    include McastPerfTest::Constants

    def initialize(options)
      # Find sending interval and number of sends
      #interval    = 1.0 /
      #              (options[:bitrate].to_f / (options[:pkg_length].to_f * 8)
      @send_time  = options[:time]
      interval    = (options[:packet_length] * 8).to_f / options[:bitrate].to_f
      @pkg_length = options[:packet_length] / 4
      @sends      = (0..(@send_time+interval)).step(interval).to_a
      @sends.shift
      @wifi       = options[:wifi]
      @ethernet   = options[:ethernet]
      @verbose    = options[:verbose]
    end

    def send_pocess(multicast_addr, interface, port, start_time)
      # Set-up and prepare socket
      socket = UDPSocket.new(Socket::AF_INET6)
      socket.setsockopt(Socket::IPPROTO_IPV6,
                            Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
      socket.setsockopt(
        Socket::IPPROTO_IPV6,
        Socket::IPV6_MULTICAST_IF,
        [interface_idx(interface)].pack('i')
      )

      # Wait until start time to make sure all processes are ready
      sleep(start_time - Time.now)

      # Begin sending loop
      @sends.each_with_index do | time,idx |
        # Calculate sleep time, and skip if we are late
        sleep_time = (start_time + time) - Time.now
        if sleep_time < 0
          next
        else
          sleep(sleep_time)
        end

        # Make the index into a 32-bit unsigned int, network byte order
        msg = [idx].pack("I>")
        socket.send(msg * @pkg_length, 0, multicast_addr, port)
      end
    end

    def run
      # Set start time and let processes start
      start_time = Time.now + STARTUP_DELAY

      # Spawn two child processes, responsible for each own interface
      pid_eth = fork do
        send_pocess(ETH_MULTICAST_ADDR, @ethernet, ETH_PORT, start_time)
      end
      pid_wifi = fork do
        send_pocess(WIFI_MULTICAST_ADDR, @wifi, WIFI_PORT, start_time)
      end

      if @verbose
        bar = TTY::ProgressBar.new("Sending [:bar]", total: @send_time)
        @send_time.times do
          sleep(1)
          bar.advance(1)
        end
      end

      # Wait for them to finish
      Process.wait(pid_eth)
      Process.wait(pid_wifi)

    end

  end # class
end # module
