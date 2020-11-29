run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    # gem 'sidekiq', '~> 6.1'
    gem 'devise'
    gem 'tiddle'
    # gem 'cancancan'
    gem 'active_model_serializers', '~> 0.10.0'
    # gem 'activestorage-aliyun'
    gem 'rest-client'
    # gem 'rails-i18n'

    # for rails admin
    # gem 'mini_magick'
    # gem 'rails_admin'

    # gem 'rqrcode' # to generate basic QR code
    # gem 'aliyun-sms' # to send SMS via Aliyun SMS

    # CHINA payments
    # gem 'wx_pay'
    # gem 'alipay', '~> 0.15.1'

    # fix some lib-error
    gem 'rb-readline'
    gem 'dotenv-rails'

  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  gem 'pry-byebug'
  gem 'pry-rails'
  RUBY
end

# gsub_file 'Gemfile', "source 'https://rubygems.org'", "source 'https://gems.ruby-china.com'"
# gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")
gsub_file('Gemfile', /gem 'jbuilder'/, "# gem 'jbuilder'")

# Dev environment
########################################
# gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')
# gsub_file('config/environments/development.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')

# Production environment
########################################
# gsub_file('config/environments/production.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')

# Staging environment
########################################
# run 'cp config/environments/production.rb config/environments/staging.rb'

# # Set timezone
# inject_into_file 'config/application.rb', after: "config.load_defaults 6.0\n" do
#   <<-RUBY
#     config.time_zone = 'Beijing'
#     config.active_record.default_timezone = :local
#   RUBY
# end

# Layout -- this is only for Rails 6 +
########################################

# README
#######################################
markdown_file_content = <<-MARKDOWN
Rails app generated with [brainchild-tech/rails-templates](https://github.com/brainchild-tech/rails-templates).
MARKDOWN
file 'README.md', markdown_file_content, force: true

########################################
# AFTER BUNDLE
########################################
# 1. Devise + Tiddle
# 2. Active Storage config
# 3. User serializer

after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route <<~RUBY
    root to: 'pages#home'
  RUBY

  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"}  before_action :authenticate_user!
    end
  RUBY

  # devise views
  ########################################
  generate('devise:views')

  # generate Cancancan
  # generate('cancan:ability')

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'
  # environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'staging'

  # Webpacker / Yarn
  ########################################
  # run 'mkdir app/javascript/stylesheets'
  # run 'yarn add popper.js jquery bootstrap'

  # Tailwindcss configs
  run 'yarn add tailwindcss@1.9.6'
  run 'rm app/assets/stylesheets/application.css'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/application.scss > app/assets/stylesheets/application.scss'

  # uncomment this when you want to generate Tailwindcss full config file
  # run 'npx tailwindcss init app/javascript/stylesheets/tailwind.config.js --full'

  # add tailwind into postcss plugin
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/postcss.config.js > postcss.config.js'

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  # run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  # git add: '.'
  # git commit: "-m 'Initial commit with devise template from https://github.com/lewagon/rails-templates'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')

  # DOCKERFILE, PROCFILE, APP.JSON
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/Dockerfile > Dockerfile'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/Procfile > Procfile'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/app.json > app.json'

  # Active Storage & Aliyun
  rails_command('active_storage:install')

  # Add Aliyun to config/storage.yml
  # inject_into_file 'config/storage.yml', before: 'test:' do
  #   <<~YAML
  #   aliyun:
  #     service: Aliyun
  #     access_key_id: <%= Rails.application.credentials.dig(:aliyun, :access_key_id) %>
  #     access_key_secret: <%= Rails.application.credentials.dig(:aliyun, :access_key_secret) %>
  #     bucket: <%= Rails.application.credentials.dig(:aliyun, :bucket) %>
  #     endpoint: <%= Rails.application.credentials.dig(:aliyun, :endpoint) %>
  #     path: "/"
  #     mode: public
  #   YAML
  # end

  # migrate
  rails_command 'db:migrate'
end
