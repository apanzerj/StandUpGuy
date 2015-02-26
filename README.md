[![Coverage Status](https://img.shields.io/coveralls/apanzerj/StandUpGuy.svg)](https://coveralls.io/r/apanzerj/StandUpGuy) [![Test Status](https://travis-ci.org/apanzerj/StandUpGuy.svg?branch=master)](https://travis-ci.org/apanzerj/StandUpGuy)

# Standupguy

Quickly and easily manage your daily standup from the command line.

## Installation

Install it yourself as:

    $ gem install Standupguy

## Usage
  
### Adding an item

Automatically looks up your ticket subject for Zendesk Tickets. You need to have your username and api key in your ENV. zendesk_user / zendesk_pass

    $ standupguy https://foo.zendesk.com/tickets/2

    $ standupguy I did a thing today

### Viewing your standup

Text based: 
    
    $ standupguy 
    $ standupguy -r TEXT
    
HTML Report

    $ standupguy --report HTML
    
Email Report (Mac OS Only)

    $ standupguy --retort EMAIL

## Contributing

1. Fork it ( https://github.com/[my-github-username]/Standupguy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
