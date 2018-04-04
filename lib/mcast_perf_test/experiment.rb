module McastPerfTest
  def self.experiment(name, clients, bitrates, package_sizes, wifi, ethernet)
    date_string = Time.now.strftime "%Y%m%d_%H%m"

    bitrates.each do | bitrate |
      package_sizes.each do | size |
        sender = Sender.new(
          {bitrate: bitrate,
           pkg_length: size,
           wifi: wifi,
           ethernet: ethernet})
        sender.run
        collector = Collector.new(name + date_string, clients)
        collector.run

        # Sleep to let possible congestion pass
        sleep(10)
      end
    end
  end
end # module
