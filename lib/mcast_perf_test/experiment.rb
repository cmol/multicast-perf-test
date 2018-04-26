require 'tty-progressbar'
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
          _b#{bitrate.to_s.rjust(bitrates.max.to_s.length,"0")}\
          _p#{size.to_s.rjust(package_sizes.max.to_s.length,"0")}\
          .dat", clients)
        collector.run

        # Sleep to let possible congestion pass
        bar = TTY::ProgressBar.new("Sleeping [:bar] :percent", total: 10)
        bar.resize
        10.times do
          sleep(1)
          bar.advance(1)
        end
      end
    end
  end
end # module
