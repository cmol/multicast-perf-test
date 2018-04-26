module McastPerfTest
  def self.experiment(opt)
    # Pickup config for experiment
    name          = opt[:name]
    clients       = opt[:clients]
    bitrates      = opt[:bitrates]
    package_sizes = opt[:packets]
    date_string   = Time.now.strftime "%Y%m%d_%H%m"

    bitrates.each do | bitrate |
      package_sizes.each do | size |
        opt[:bitrate] = bitrate
        opt[:packet_length] = size
        sender = Sender.new(opt)
        sender.run
        collector = Collector.new(
          "#{name}_#{date_string}\
          _b#{bitrate.to_s.rjust(bitrates.max.length,"0")}\
          _p#{size.to_s.rjust(package_sizes.max.length,"0")}.dat", clients)
        collector.run

        # Sleep to let possible congestion pass
        sleep(10)
      end
    end
  end
end # module
