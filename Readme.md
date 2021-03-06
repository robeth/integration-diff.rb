# IntegrationDiff

Currently this supports only RSpec.

### Installation

```rb
gem 'integration-diff'
```

### Configuration

Include `integration-diff` in your rspec `spec_helper` and configure 6 variables
which will be used while taking screenshots. Make sure that `enable_service` is
set to true if images need to be uploaded.

**NOTE:** Make sure that that project exists in service with `project_name`. Also
api key can be obtained by loggin into service and visiting `/api_key`.


```rb
IntegrationDiff.configure do |config|
  # configure domain to which all images have to be uploaded.
  config.base_uri = "http://idf.dev"

  # configure project name to which images belong to.
  config.project_name = "idf"

  # configure api_key required to authorize api access
  config.api_key = ENV["IDIFF_API_KEY"]

  # configure js driver which is used for taking screenshots.
  config.javascript_driver = "poltergeist"

  # configure service to mock capturing and uploading screenshots
  config.enable_service = !!ENV["IDIFF_ENABLE"]

  # configure logger to log messages. optional.
  config.logger = Rails.logger
end
```

After configuration, include `IntegrationDiff::Dsl` in your `spec_helper` and
configure before and after suite so that suite interacts with the service.


```rb
RSpec.configure do |config|
  config.include IntegrationDiff::Dsl

  config.before(:suite) do
    IntegrationDiff.start_run
  end

  config.after(:suite) do
    IntegrationDiff.wrap_run
  end
end
```

### Usage

In your specs, simply use `idiff` helper. make sure that you pass unique identifier
to screenshots that you take. unique identifier helps in differentiating this
screenshot taken from other screenshots.


```rb
describe "Landing page" do
  it "has a big banner" do
    visit root_path
    idiff.screenshot("unique-identifier")
  end
end
```

### Concurrency

By default, when all the screenshots are collected, and before suite ends, this
gem will upload all the screenshots taken. `IntegrationDiff.wrap_run` is the
method responsible for the same.

However, if you want to upload screenshots as and when they are taken, this gem
has soft dependency on `concurrent-ruby` gem. Make sure that this gem is
**required** before capturing screenshots, and see the magic yourself :)
