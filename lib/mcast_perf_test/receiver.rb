require 'socket'
require 'ipaddr'

module McastPerfTest
  class Receiver
    include McastPerfTest::Helpers
    include McastPerfTest::Constants

    def initialize(options)
      @samples  = options[:samples]
      @ethernet = options[:ethernet]
      @wifi     = options[:wifi]
    end

    def receive_pocess(multicast_addr, filename, interface, port)
      # Prepare samples array
      samples = Array.new(@samples, Time.at(0))

      # Set-up and prepare sockets
      socket = UDPSocket.new(Socket::AF_INET6)
      ip     = IPAddr.new(multicast_addr).hton +
                  [interface_idx(interface)].pack('i')
      socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, ip)
      socket.bind("::", port)

      # Prepare signal handler
      Signal.trap("HUP") do
        # Firstly, close the socket
        socket.close

        # Open and write results to file, but ensure it's absence at first
        File.delete(filename) if File.exist?(filename)
        File.open(filename, 'w') do | file |
          samples.each_with_index do | sample,idx |
            file.write("#{idx},#{sample.tv_sec + sample.tv_usec / 1000000.0}")
          end
        end

        # End the child process gracefully
        exit 0
      end

      # Start receiving data
      loop do
        msg, info = socket.recvfrom(1500)
        current = Time.now
        samples[msg[0..3].unpack("L>").first] = current
      end

    end

    def run
      # Spawn two child processes, responsible for each own interface
      pid_eth = fork do
        receive_pocess(ETH_MULTICAST_ADDR, ETH_FILE, @ethernet, ETH_PORT)
      end
      pid_wifi = fork do
        receive_pocess(WIFI_MULTICAST_ADDR, WIFI_FILE, @wifi, WIFI_PORT)
      end

      # Ready a TCP socket and wait for master to connect
      server = TCPServer.new("::", ADM_PORT)
      connection = server.accept

      # Ask children to terminate and write out their data
      Process.kill("HUP", pid_eth)
      Process.kill("HUP", pid_wifi)

      # Wait for them to finish
      Process.wait(pid_eth)
      Process.wait(pid_wifi)

      # Read ETH data as a baseline
      samples = []
      File.open(ETH_FILE).each_line do | line |
        idx,time = line.split(",")
        samples[idx.to_i] = Time.at(time.to_f)
      end

      # Compare with WIFI and send to master
      File.open(WIFI_FILE).each_line do | line |
        idx,time = line.split(",")
        idx = idx.to_i
        time = Time.at(time.to_f)

        if time.to_i == 0
          connection.puts [idx,0].pack("L>G")
        else
          connection.puts [idx,(time - samples[idx]).to_f].pack("L>G")
        end
      end

      # Close connection
      connection.close
    end

  end # class
end # module
