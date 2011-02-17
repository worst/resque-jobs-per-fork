require 'rubygems'
require 'bundler/setup'

require 'test/unit'

$:.unshift File.expand_path('../', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'resque-jobs-per-fork'

Bundler.require(:default, :development)
