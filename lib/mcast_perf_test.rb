require "mcast_perf_test/version"

module McastPerfTest
  module Constants
    ETH_MULTICAST_ADDR  = "ff02::100"
    ETH_SOURCE_ADDR     = "fd00::1"
    WIFI_MULTICAST_ADDR = "ff02::200"
    WIFI_SOURCE_ADDR    = "fd01::1"
    ADM_PORT            = 5000
    ETH_PORT            = 5001
    WIFI_PORT           = 0xbeee
    ETH_FILE            = "/tmp/eth_samples"
    WIFI_FILE           = "/tmp/wifi_samples"
    STARTUP_DELAY       = 1.0                 # Defined in seconds
  end

  module Helpers
    def interface_idx(interface)
      `cat /sys/class/net/#{interface}/ifindex`.chomp.to_i
    end
  end
end

require "mcast_perf_test/sender"
require "mcast_perf_test/receiver"
require "mcast_perf_test/collector"
require "mcast_perf_test/experiment"
require "mcast_perf_test/delay_tester"
