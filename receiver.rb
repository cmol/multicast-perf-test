#!/usr/bin/env ruby

require 'socket'
require 'ipaddr'
require 'optparse'

ETH_MULTICAST_ADDR  = "ff02::100"
ETH_SOURCE_ADDR     = "fd00::1"
WIFI_MULTICAST_ADDR = "ff02::200"
WIFI_SOURCE_ADDR    = "fd01::1"
PORT                = 5000
ETH_PORT            = 5001
WIFI_PORT           = 5002
ETH_FILE            = "/tmp/eth_samples"
WIFI_FILE           = "/tmp/wifi_samples"

options = {
  ethernet: nil,
  wifi: nil,
  samples: 200_000
}

parser = OptionParser.new do|opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on('-e', '--ethernet interface', 'Ethernet interface') do |ethernet|
    options[:ethernet] = ethernet;
  end
  opts.on('-w', '--wifi interface', 'WiFi interface') do |wifi|
    options[:wifi] = wifi;
  end
  opts.on('-s', '--samples number', 'Number of samples') do |samples|
    options[:samples] = samples.to_i;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

  if ARGV.length < 2
    puts opts
    exit 1
  end
end
parser.parse!

# Prepare array for received samples
samples = Array.new(options[:samples], Time.at(0))

def receive_pocess(multicast_addr, filename, interface, port)
  # Set-up and prepare sockets
  socket = UDPSocket.new(Socket::AF_INET6)
  ip     = IPAddr.new(multicast_addr).hton +
    [`cat /sys/class/net/#{interface}/ifindex`.chomp.to_i].pack('i')
  socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, ip)
  socket.bind("::", port)

  # Prepare signal handler
  Signal.trap("HUP") do
    # Firstly, close the socket
    socket.close

    # Open and write results to file, but ensure it's absence at first
    File.delete(filename) if File.exist?(filename)
    File.open(filename, 'w') do | file |
      samples.each_with_index do | sample,index |
        file.write("#{index},#{sample.tv_sec + sample.tv_usec / 1_000_000.0}")
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

# Spawn two child processes, responsible for each own interface
pid_eth = fork do
  receive_pocess(ETH_MULTICAST_ADDR, ETH_FILE, options[:ethernet], ETH_PORT)
end
pid_wifi = fork do
  receive_pocess(WIFI_MULTICAST_ADDR, WIFI_FILE, options[:wifi], WIFI_PORT)
end

# We don't need this array here
samples = nil

# Ready a TCP socket and wait for master to connect
server = TCPServer.new("::", PORT)
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
