# McastPerfTest

This gem is designed to test multicast performance in a WiFi environment, specifically with testing new standards as 802.11aa, included in 802.11-2016. Work on this is part of a master thesis, and is as such not intended for other uses currently.

## Requirements
To use this gem, both a wired and a wireless network needs to be present.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcast_perf_test'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mcast_perf_test

## Usage

The gem is split into four tools:

- receiver
- sender
- collector
- experiment

### receiver usage
```
Usage: ./bin/mcastperf receiver [options]
    -e, --ethernet interface         Ethernet interface
    -w, --wifi interface             WiFi interface
    -s, --samples number             Number of samples
    -l, --loop                       Loop (for experiment)
    -h, --help                       Displays Help

```

The receiver is used to run either a single test, or a multiple of tests on the system. Each client in the multicast network must run the receiver. the receiver will hang, waiting for a connection to collect the data even after the master have finished sending data. If the loop option is used, multiple consecutive runs of the client will be made until interrupted by the system.

### sender
```
Usage: ./bin/mcastperf sender [options]
    -p, --packet length              Packet Length (bytes)
    -b, --bitrate rate               Bitrate (kilobit per second)
    -e, --ethernet interface         Ethernet interface
    -w, --wifi interface             WiFi interface
    -h, --help                       Displays Help
```

The sender is responsible for sending packets on the wireless and wired interface simultaneously at the packet rate and size specified.

### collector
```
Usage: ./bin/mcastperf collector [options]
    -n, --name name                  Experiment name
    -c, --clients fd00::1,..         IPv6 address of clients
    -h, --help                       Displays Help
```

The collector should be run after the sender, and will collect data from all the clients. The collector is not limited to running on the same host as the sender, though external coordination or manual handling is needed.

### experiment
```
Usage: ./bin/mcastperf experiment [options]
    -e, --ethernet interface         Ethernet interface
    -w, --wifi interface             WiFi interface
    -n, --name name                  Experiment name
    -c, --clients fd00::1,..         IPv6 address of clients
    -b, --bitrates start,stop,step   Bitrates for experiment (kilobit pr second)
    -p, --packages start,stop,step   Packet lengths for experiment (bytes)
    -h, --help                       Displays Help
```

The experiment is a combination of the sender and collector. The experiment will iterate over the bitrates and package lengths given, and will collect the data after each run.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cmol/mcast_perf_test.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
