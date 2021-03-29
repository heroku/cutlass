# Cutlass

Hack and slash your way to Cloud Native Buildpack (CNB) stability with cutlass! This library is similar in spirit to [heroku_hatchet](https://github.com/heroku/hatchet), but instead of building on Heroku infrastructure cutlass utilizes [pack](https://buildpacks.io/docs/tools/pack/) to locally build and verify buildpack behavior.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cutlass'
```

## Setup

TODO: `cutlass init` command

It's assumed you've already got your project set up with rspec. If not see https://github.com/heroku/hatchet#hatchet-init, though using Hatchet is not required to use cutlass.

## Initial Config

In your `spec_helper.rb` configure your default stack:

```ruby
Cutlass.configure do |config|
  config.default_builder = "heroku/buildpacks:18"

  # Where do your test fixtures live?
  config.default_repos_dir = [File.join(__dir__, "..", "repos", "ruby_apps")]

  # Where does your buildpack live?
  config.default_buildpack_paths = [File.join(__dir__, "..")]
end
```

## Use

Initialize an instance with `Cutlass::App.new`

```ruby
Cutlass::App.new(
  "ruby-getting-started"
  config: { RAILS_ENV: "production" },
  builder: "heroku/heroku:18",
  buildpacks: ["heroku/nodejs-engine", File.join("..")],
  exception_on_failure: false
)
```

Once initialized call methods on the instance:

```ruby
Cutlass::App.new("ruby-getting-started").transaction do |app|
  app.pack_build do |result|
    expect(result.stdout).to include("SUCCESS")
  end

  app.start_container do |container|
    response = Excon.get("http://localhost:#{container.port}/", :idempotent => true, :retry_limit => 5, :retry_interval => 1)
    expect(response.body).to eq("Welcome to rails")

    expect(container.get_file_contents("Gemfile.lock")).to_not include("BUNDLED WITH")
  end

  app.run_multi!("ruby -v") do |result|
    expect(result.to_s).to match("2.7.2")
    expect(result.status).to eq(0)
  end
end
```


## API

### Cutlass::App Init options:

- @param repo_name [String] the path to a directory on disk, or the name of a directory inside of the `config.default_repos_dir`.
- @param builder [String] the name of a CNB "builder" used to build the app against. Defaults to `config.default_builder`.
- @param buildpacks [Array<String>] the array of buildpacks to build the app against. Defaults to `config.default_buildpack_paths`.
- @param config [Hash{Symbol => String}, Hash{String => String}] env vars to set against the app before it is built.
- @param exception_on_failure: [Boolean] when truthy failures on `app.pack_build` will result in an exception. Default is true.

### Cutlass::App object API

- `app.transaction` Yields a block with itself. Copies over the example repo to a temporary path. When the block is finished executing, the path is cleaned up and the `teardown` callbacks are called on the application.
- `app.pack_build` Yields a block with a `Cutlass::BashResult`. Triggers a build via the `pack` CLI. It can be invoked multiple times inside of a transaction for testing cache behavior.
- `app.in_dir` Yields a block with itself. Copies over example repo to a temporary path. When the block is finished executing the path is cleaned up.
- `app.teardown` Triggers any "teardown" callbacks, such as waiting on `run_mutli` blocks to complete.
- `app.start_container` boots a container instance and connects it to a local port. Yields a `Cutlass::Container` instance with information about the container such as the port it is connected to.
- `app.run_multi` takes a string with a shell command and executes it async. Yields a `Cutlass::BashResult` object.

### Cutlass::BashResult

- `result.stdout`
- `result.stderr`
- `result.status`
- `result.success?`

### Cutlass::Container

- `container.port`
- `container.run`
- `container.contains_file?`
- `container.file_contents`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cutlass. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/cutlass/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cutlass project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/cutlass/blob/main/CODE_OF_CONDUCT.md).
