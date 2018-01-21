# NECMockServer

Project represents Ruby gem of simple Rack server designed for use as mock server of third part application in unit tests.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nec_mock_server'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nec_mock_server

## Usage

Example of usage class NEC::MockServer::Server:

```ruby
require 'nec_mock_server'

class SubAppRouter < NEC::MockServer::Router
  def route(parts, request_data)
    case parts[:resource]
      when "/getData"
        ok(request_data, JSON_HEADER)
      when "/", ""
        home
      else
        not_found(parts[:resource])
    end
  end
end

app_config = {
    application_name: 'Sub App name',
    only_registered_awid: true
}

mock_server = NEC::MockServer::Server.new(SubAppRouter, app_config)
mock_server.run!(9001)
```

Example of usage class NEC::MockServer::Server:

```ruby
require 'nec_mock_server'

# define absolute path to directory with run.rb of your sub app
sub_app_data_path = File.expand_path('../../mock_servers/sub_app', __FILE__)
sub_app_data = NEC::MockServerStarter.new(sub_app_data_path)
sub_app_data.run!
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MarekFiltes/nec_mock_server. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NecMockServer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/MarekFiltes/nec_mock_server/blob/master/CODE_OF_CONDUCT.md).
