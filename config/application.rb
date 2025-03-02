require_relative "boot"

require "rails/all"
require "aws-sdk-ssm"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RjfcWebsiteRuby
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Fetch SECRET_KEY_BASE from AWS SSM Parameter Store in production
    if Rails.env.production?
      ssm_client = Aws::SSM::Client.new(region: ENV['AWS_REGION'] || 'ap-southeast-2')

      begin
        secret_key_base_param = ssm_client.get_parameter(
          name: 'SECRET_KEY_BASE',
          with_decryption: true
        )
        secret_key_base = secret_key_base_param.parameter.value
        Rails.application.secret_key_base = secret_key_base # 👈 Explicitly set it
      rescue Aws::SSM::Errors::ParameterNotFound
        raise "SECRET_KEY_BASE parameter not found in AWS SSM Parameter Store"
      end
    end
  end
end
