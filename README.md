# Capistrano::Hutch::Systemd

Hutch + SystemD integration for Capistrano

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add capistrano-hutch-systemd

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install capistrano-hutch-systemd

Or add in your Gemfile :

```
gem 'capistrano-hutch-systemd'
```

And then 

    $ bundle install

Install hutch to your server before running deployment :

    $ cap {your_stage} hutch:install

## Usage

In your Capfile :

```
require 'capistrano/hutch'
install_plugin Capistrano::Hutch
install_plugin Capistrano::HutchPlugin::Systemd
```

Add preference in your deploy.rb

```
set :hutch_default_hooks, true
set :hutch_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
set :hutch_roles, :app
set :hutch_use_config_file, true
set :hutch_config_files, ['hutch.yml']
set :hutch_service_unit_user, :user
set :hutch_log, '/path/to/shared/log/events.log'
set :hutch_error_log, '/path/to/shared/log/events.log'
```

## Example

[TODO] Create example

## Development

The code was modified from https://github.com/seuros/capistrano-sidekiq

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/yunanhelmy/capistrano-hutch-systemd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yunanhelmy/capistrano-hutch-systemd/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Capistrano::Hutch::Systemd project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yunanhelmy/capistrano-hutch-systemd/blob/master/CODE_OF_CONDUCT.md).
