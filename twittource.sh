#!/bin/sh

# if using rvm:
# rvm use 1.9.2@twittource --create

# install gems:
# gem install twitter yajl-ruby
# using bundler:
# bundle install

# all config in twittource.conf:
ruby twittource.rb  | gource --load-config twittource.conf -

# fullscreen with 640x480 display:
# ruby twittource.rb  | gource --load-config twittource.conf -640x480 -f -
