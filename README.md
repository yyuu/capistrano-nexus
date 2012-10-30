# capistrano-nexus

A Capistrano recipe to deploy [Sonatype Nexus](http://www.sonatype.org/nexus/).

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-nexus'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-nexus

## Usage

To deploy Sonatype Nexus, add following in your `config/deploy.rb`.

    # in "config/deploy.rb"
    require 'capistrano-nexus'

The following options are available to manage your installation of Sonatype Nexus.

 * `:nexus_version` - The version of Sonatype Nexus.
 * `:nexus_archive_uri` - The download URL of Sonatype Nexus.
 * `:nexus_current_path` - The path to the current installation of Sonatype Nexus. Use `:current_path` by default.
 * `:nexus_release_path` - The path to the new installation of Sonatype Nexus. Use `:release_path` by default.
 * `:nexus_sonatype_work_path` - The path to the `sonatype-work` directory.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
