[![Coverage Status](https://img.shields.io/coveralls/apanzerj/Standupguy.svg)](https://coveralls.io/r/apanzerj/Standupguy) [![Test Status](https://travis-ci.org/apanzerj/Standupguy.svg?branch=master)](https://travis-ci.org/apanzerj/Standupguy)

# Standupguy

Quickly and easily manage your daily standup from the command line.

## Installation

Install it yourself as:

    $ gem install Standupguy

## Usage
  
### Adding an item

    $ standupguy https://foo.zendesk.com/tickets/2

    $ standupguy I did a thing today

### Viewing your standup

    $ standupguy --report TEXT

    $ standupguy --report HTML

## Contributing

1. Fork it ( https://github.com/[my-github-username]/Standupguy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
