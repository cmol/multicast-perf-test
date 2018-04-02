require 'socket'
require 'ipaddr'

module McastPerfTest
  class Collector
    include McastPerfTest::Helpers
    include McastPerfTest::Constants

    def initialize(name, clients)
      @clients   = clients
      @name      = name
      @collected = {}
    end

    def collect(client)
      socket = TCPSocket.new client, ADM_PORT

      samples = []
      while line = socket.gets
        idx, delay = line.unpack("L>G")
        samples[idx] = delay
      end
      socket.close

      samples
    end

    def write_data
      # Prepare header
      header = "index,#{@collect.keys.map {|key| key.to_s}.join(",")}\n"

      # Prepare array dimensions
      formatted = Array.new(@collected.first.last.length,
                            Array.new(@collect.keys.length + 1, nil))

      # Prepare array for file write
      @collect.keys.each_with_index do | key, key_idx |
        @collect[key].each_with_index do | sample, idx |
          formatted[idx][key_idx] = sample
        end
      end

      # Write to file
      File.open(@name, 'w') do | file |
        # Write header
        file.write(header)

        # Write samples
        formatted.each_with_index do | sample,idx |
          file.write("#{idx},#{sample.join(',')}")
        end
      end
    end

    def run
      # Collect data from clients
      @clients.each do | client |
        @collected[client] = collect
      end

      write_data
    end

  end # class
end # module
