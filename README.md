# RSpock

RSpock is a testing and specification framework built on top of Minitest. It intends to bring productivity back in the hands of developers with its incredibly simple yet highly expressive specification language.

Note: RSpock is heavily inspired by Spock for the Groovy programming language.

## Goals

* High readability, expressiveness, maintainability and productivity: Take back your very precious developer time!
* Encourage code reuse through expressive data-driven tests

## Features

* BDD-style code blocks: Given, When, Then, Cleanup, Where
* Data-driven testing with incredibly expressive table-based Where blocks
* Expressive assertions: Use familiar comparison operators `==` and `!=` for assertions!
* (Planned) BDD-style custom reporter that outputs information from Given, When, Then and Cleanup blocks
* (Planned) RSpock syntax pre-processor

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspock'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspock

### Rails

If you are using Rails, it is necessary to add a filter to *Rails.backtrace_cleaner* for source mapping to work, so that you get proper line numbers in Minitest backtraces. For your convenience, we've built a Rails Generator just for that:

    $ rails g rspock:install

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rspock. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RSpock project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rspock/blob/master/CODE_OF_CONDUCT.md).
