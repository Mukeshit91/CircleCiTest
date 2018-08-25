require 'rbconfig'
require 'cucumber/formatter/unicode'
require 'capybara'
require 'capybara/dsl'
require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'
require 'yaml'

config = YAML.load_file('config/config.yml')
LOGIN_USER = config['login_user']
LOGIN_PASSWORD = config['login_password']
EXCEL_WORKBOOK = config['excel_workbook']
EXCEL_WORKSHEET = config['excel_worksheet']
Capybara.default_driver = :selenium
Capybara.default_max_wait_time = 30
Capybara.app_host = config['base_url']

Before do
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app,
                                   browser: :chrome,
                                   desired_capabilities: {
                                       "chromeOptions" => {
                                           "args" => %w{ window-size=1024,768 }
                                       }
                                   })
  end
end

Capybara::Screenshot.register_filename_prefix_formatter(:selenium) do |fault|
  'my_screenshot'
end

Capybara.run_server = false

World(Capybara)

Dir['features/support/*rb'].each { |f| require File.expand_path(f) }