## README

## For WeChat MP

`rails new YOUR_APP_NAME -T --database=postgresql --skip-webpack-install -m https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/wxmp-no-web.rb`

* Gemfile source ruby-china.com

* Authentication with Devise/Tiddle

* Active Storage + Aliyun SDK

* Custom user sessions for WXMP login

* Active Model Serializer

* Dockerfile, Procfile, app.json

* Sidekiq & redis ready

### With webpack

`rails new YOUR_APP_NAME -T --database=postgresql -m https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/wxmp.rb`

### With web view (admin etc.) + Tailwind

`rails new YOUR_APP_NAME -T --database=postgresql -m https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/wxmp-tailwind.rb`

* Tailwindcss v. 1.9.6

* Rails Admin ready

## For Rails Web App with Tailwindcss

`rails new YOUR_APP_NAME -T --database=postgresql -m ~/code/brainchild/rails-templates/web-tailwind.rb`

* Tailwindcss v. 1.9.6

* Rails Admin ready

* Active storage installed, but storage service not yet configured

* Devise installed

* Active model serializer installed

* Cancancan an option, not yet installed/generated


## For Rails Web App with Vue.js

`rails new YOUR_APP_NAME --database=postgresql --webpack=vue -T -m https://raw.githubusercontent.com/brainchild-tech/rails-templates/master/vue.rb`

* Tailwindcss v. 1.9.6

* Rails Admin ready

* Active storage installed, but storage service not yet configured

* Devise installed

* Active model serializer installed

* Cancancan an option, not yet installed/generated
