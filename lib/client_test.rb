require 'net/http'
require 'uri'
require 'json'
require './OctoClient.rb'

params = { :q => "tetris+language:assembly"}

puts OctoClient.make_request params
