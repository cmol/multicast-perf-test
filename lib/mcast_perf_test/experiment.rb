require 'tty-progressbar'
module McastPerfTest
  def self.experiment(opt)
    # Pickup config for experiment
    name          = opt[:name]
    clients       = opt[:clients]
    bitrates      = opt[:bitrates]
    package_sizes = opt[:packets]
    date_string   = Time.now.strftime "%Y%m%d_%H%m"
    total         = bitrates.length * package_sizes.length * opt[:time]
    bar           = TTY::ProgressBar.new("Working [:bar] :percent :eta",
                                         total: total)

    bitrates.each do | bitrate |
      package_sizes.each do | size |
        opt[:bitrate]       = bitrate
        opt[:packet_length] = size
        opt[:bar]           = bar
        sender              = Sender.new(opt)
        bar.log("Sending for bitrate #{bitrate} and pkg size #{size}")
        sender.run
        collector = Collector.new(
          "#{name}_#{date_string}\
_b#{bitrate.to_s.rjust(bitrates.max.to_s.length,"0")}\
_p#{size.to_s.rjust(package_sizes.max.to_s.length,"0")}\
.dat", clients)
        bar.log("Collecting for for bitrate #{bitrate} and pkg size #{size}")
        collector.run

        # Sleep to let possible congestion pass
        bar.log("Sleeping")
        sleep(10)
      end
    end
  end
end # module
