run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    # gem 'sidekiq', '~> 6.1'
    gem 'devise'
    gem 'tiddle'
    gem 'active_model_serializers', '~> 0.10.0'
    gem 'activestorage-aliyun'
    gem 'rest-client'
    gem 'rails-i18n'

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

gsub_file 'Gemfile', "source 'https://rubygems.org'", "source 'https://gems.ruby-china.com'"
# gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

# Assets
########################################
# run 'rm -rf app/assets/stylesheets'
# run 'rm -rf vendor'
# run 'curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip'
# run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'

# Dev environment
########################################
# gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')
gsub_file('config/environments/development.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')

# Production environment
########################################
gsub_file('config/environments/production.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')

# Staging environment
########################################
run 'cp config/environments/production.rb config/environments/staging.rb'

# Set timezone
inject_into_file 'config/application.rb', after: "config.load_defaults 6.0\n" do
  <<-RUBY
    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local
  RUBY
end

# Layout
########################################
# NEED TO CHECK
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
        <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end
gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)


# README
########################################
# markdown_file_content = <<-MARKDOWN
# Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
# MARKDOWN
# file 'README.md', markdown_file_content, force: true

# Generators
########################################
# generators = <<~RUBY
#   config.generators do |generate|
#     generate.assets false
#     generate.helper false
#     generate.test_framework :test_unit, fixture: false
#   end
# RUBY

# environment generators

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
  # generate('simple_form:install', '--bootstrap')
  # generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  # route "root to: 'pages#home'"
  route <<~RUBY
  scope "(:locale)", locale: /en|cn/ do
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        # Devise routes for API clients (custom sessions controller)
        devise_scope :user do
          post 'login', to: 'user_sessions#create', as: 'login'
          post 'manual_login', to: "user_sessions#manual_create"
        end
        get 'users/:id', to: "users#show"
        put 'users/update', to: 'users#update'
        # put 'users/update-phone', to: 'user_sessions#update_phone'
        # put 'users/admin-register', to: 'user_sessions#admin_register'
      end
    end
  end
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

  # Tiddle
  ########################################
  generate(:model, 'AuthenticationToken', 'body:string', 'user:references', 'last_used_at:datetime', 'ip_address:string', 'user_agent:string')
  # add :token_authenticatable
  # replace devise :database_authenticatable, :registerable, :recoverable, :trackable, :validatable
  # with devise :database_authenticatable, :registerable, :recoverable, :trackable, :validatable, :token_authenticatable
  inject_into_file 'app/models/user.rb', after: ":validatable" do
    ", :token_authenticatable"
  end

  inject_into_file 'app/models/user.rb', before: "end" do
    # "has_many :authentication_tokens\n"
    <<~RUBY
      has_many :authentication_tokens
    RUBY
  end

  # WeChat User Attributes
  ########################################
  generate('migration AddBasicColumnsToUsers open_id session_key avatar nickname phone_number language gender city province region country is_admin:boolean')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"}  before_action :authenticate_user!
    end
  RUBY

  # Base controller
  run 'mkdir app/controllers/api'
  run 'mkdir app/controllers/api/v1'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/base_controller.rb > app/controllers/api/v1/base_controller.rb'

  # User Sessions & Users controller
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/user_sessions_controller.rb > app/controllers/api/v1/user_sessions_controller.rb'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/users_controller.rb > app/controllers/api/v1/users_controller.rb'

  # Replace application_record
  run 'rm app/models/application_record.rb'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/application_record.rb > app/models/application_record.rb'

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # generate User serializer
  generate('serializer', 'User')
  gsub_file('app/serializers/user_serializer.rb', 'attributes :id', 'attributes :id, :email, :open_id, :session_key, :nickname, :avatar, :gender, :language, :region, :province, :city, :country, :is_admin')

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'staging'

  # Webpacker / Yarn
  ########################################
  run 'mkdir app/javascript/stylesheets'
  # run 'yarn add popper.js jquery bootstrap'

  # Tailwindcss configs
  run 'yarn add tailwindcss'
  # run 'npx tailwindcss init app/javascript/stylesheets/tailwind.config.js --full'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/tailwind.config.js > app/javascript/stylesheets/tailwind.config.js'
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/application.scss > app/javascript/stylesheets/application.scss'

  # add tailwind into postcss plugin
  run 'curl -L https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/files/postcss.config.js > postcss.config.js'

  append_file 'app/javascript/packs/application.js', <<~JS
    require("../stylesheets/application.scss");
    // document.addEventListener('turbolinks:load', () => {
      // Call your functions here, e.g:
      // initSelect2();
    // });
  JS

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

  # Add Aliyun to config/storage.yml
  inject_into_file 'config/storage.yml' do
    <<~YAML
    aliyun:
      service: Aliyun
      access_key_id: <%= Rails.application.credentials.dig(:aliyun, :access_key_id) %>
      access_key_secret: <%= Rails.application.credentials.dig(:aliyun, :access_key_secret) %>
      bucket: <%= Rails.application.credentials.dig(:aliyun, :bucket) %>
      endpoint: <%= Rails.application.credentials.dig(:aliyun, :endpoint) %>
      path: "/"
      mode: public
    YAML
  end

end
