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
        idx, delay = line.split(",")
        samples[idx.to_i] = delay.to_f
      end
      socket.close

      samples
    end

    def write_data
      # Prepare header
      header = "index,#{@collected.keys.map {|key| key.to_s}.join(",")}\n"

      # Prepare array dimensions
      #f2 = Array.new(@collected.first.last.length,
      #                      Array.new(@collected.keys.length, nil))
      # TODO: For some reason this array allocation makes all the samples from a single
      # node to the same value.. Allocating on the go is sloppy and slow, but gets the
      # job done..... Sorry future me.

      formatted = []

      @collected.keys.each_with_index do | key, key_index |
        @collected[key].each_with_index do | sample, index |
          formatted[index] = [] unless formatted[index]
          formatted[index][key_index] = sample
        end
      end

      # Remove all indexes without the correct number of samples
      formatted = formatted.reject{ | index | index.length < @collected.keys.length }

      # Write to file
      File.open(@name, 'w') do | file |
        # Write header
        file.write(header)

        # Write samples
        formatted.each_with_index do | sample,idx |
          file.write("#{idx},#{sample.join(',')}\n")
        end
      end
    end

    def run
      # Collect data from clients
      @clients.each do | client |
        @collected[client] = collect(client)
      end

      write_data
    end

  end # class
end # module
