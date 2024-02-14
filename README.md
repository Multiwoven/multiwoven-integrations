# Multiwoven Integrations

[![Gem Version](https://badge.fury.io/rb/multiwoven-integrations.svg)](http://badge.fury.io/rb/multiwoven-integrations)
[![CI](https://github.com/Multiwoven/multiwoven-integrations/actions/workflows/ci.yml/badge.svg)](https://github.com/Multiwoven/multiwoven-integrations/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/d841270f1f7a966043c1/maintainability)](https://codeclimate.com/repos/657d0a2a60265a2f2155ffca/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/d841270f1f7a966043c1/test_coverage)](https://codeclimate.com/repos/657d0a2a60265a2f2155ffca/test_coverage)


Multiwoven integrations is the collection of connectors built on top of Multiwoven protcol.

Multiwoven protocol is an open source standard for moving data between data sources to any third-part destinations.
Anyone can build a connetor with basic ruby knowledge and multiwoven protocol understanding. 

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add multiwoven-integrations


## Usage

### Source
```
source = Multiwoven::Integrations::Source::[CONNECTOR_NAME]::Client.new
source.read(sync_config)
```
### Destination

```
destination = Multiwoven::Integrations::Destination::[CONNECTOR_NAME]::Client.new
destination.write(sync_config, records)
```

### Supported methods 
Please refer [Multiwoven Protocol](https://docs.multiwoven.com/guides/architecture/multiwoven-protocol)

## Development

- **Install Dependencies**
  - Command: `bin/setup`
  - Description: After checking out the repo, run this command to install dependencies.

- **Run Tests**
  - Command: `rake spec`
  - Description: Run this command to execute the tests.

- **Interactive Prompt**
  - Command: `bin/console`
  - Description: For an interactive prompt that allows you to experiment, run this command.

- **Install Gem Locally**
  - Command: `bundle exec rake install`
  - Description: To install this gem onto your local machine, run this command.

- **Release New Version**
  - Steps:
    1. Update the version number in `rollout.rb`.
    2. Command: `bundle exec rake release`
    3. Description: This command will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

- **Bug Reports and Pull Requests**
  - Location: GitHub at https://github.com/Multiwoven/multiwoven-integrations
  - Description: Bug reports and pull requests are welcome on GitHub. This project aims to be a safe, welcoming space for collaboration.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

  - Link: [Code of Conduct](https://github.com/Multiwoven/multiwoven-integrations/blob/main/CODE_OF_CONDUCT.md)
  - Description: Contributors are expected to adhere to the project's code of conduct.
