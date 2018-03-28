#!/usr/bin/env ruby

require 'socket'
require 'ipaddr'
require 'optparse'

ETH_MULTICAST_ADDR  = "ff02::100"
ETH_SOURCE_ADDR     = "fd00::1"
WIFI_MULTICAST_ADDR = "ff02::200"
WIFI_SOURCE_ADDR    = "fd01::1"
PORT                = 5000
TEST_TIME           = 60.0

options = {
  pkg_length: nil,
  bitrate: nil,
  ethernet: nil,
  wifi: nil
}

parser = OptionParser.new do|opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on('-p', '--packet length', 'Packet Length (bytes)') do |pkg_len|
    options[:pkg_length] = pkg_len.to_f * 8;
    options[:pkg_byte_size] = pkg_len.to_i
  end

  opts.on('-b', '--bitrate rate', 'Bitrate (kilobit per second)') do |bitrate|
    options[:bitrate] = bitrate.to_f * 1000;
  end

  opts.on('-e', '--ethernet interface', 'Ethernet interface') do |ethernet|
    options[:ethernet] = ethernet;
  end
  opts.on('-w', '--wifi interface', 'WiFi interface') do |wifi|
    options[:wifi] = wifi;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

  if ARGV.length < 4
    puts opts
    exit 1
  end
end
parser.parse!

# Find sending interval and number of sends
interval = 1.0 / (options[:bitrate].to_f / options[:pkg_length].to_f)
puts interval
num_sends = TEST_TIME / interval

# Set-up and prepare sockets
eth_socket = UDPSocket.new(Socket::AF_INET6)
eth_socket.setsockopt(Socket::IPPROTO_IPV6,
                      Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
eth_socket.setsockopt(
  Socket::IPPROTO_IPV6,
  Socket::IPV6_MULTICAST_IF,
  [`cat /sys/class/net/#{options[:ethernet]}/ifindex`.chomp.to_i].pack('i')
)

wifi_socket = UDPSocket.new(Socket::AF_INET6)
wifi_socket.setsockopt(Socket::IPPROTO_IPV6,
                       Socket::IPV6_MULTICAST_HOPS, [1].pack('i'))
wifi_socket.setsockopt(
  Socket::IPPROTO_IPV6,
  Socket::IPV6_MULTICAST_IF,
  [`cat /sys/class/net/#{options[:wifi]}/ifindex`.chomp.to_i].pack('i')
)

pkg_length = options[:pkg_byte_size] / 4

# Begin sending loop
(0...num_sends.to_i).each do | idx |
  next_round = Time.now + interval
  # Make the index into a 32-bit unsigned int, network byte order
  msg = [idx].pack("I>")
  wifi_socket.send(msg * pkg_length, 0, WIFI_MULTICAST_ADDR, PORT)
  eth_socket.send(msg * pkg_length, 0, ETH_MULTICAST_ADDR, PORT)
  sleep(next_round - Time.now)
end
