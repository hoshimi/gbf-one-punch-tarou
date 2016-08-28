require 'twitter'
require 'dotenv'

Dotenv.load

NAMES = ENV['ONE_PUN_NAMES'].split(',')
HELL = ENV['INCLUDE_120_HELL'] == 'true' ? true : false

class ReliefRequest
  attr_reader :id, :name, :level

  def initialize(str)
    match = str.match(/.*参加者募集！参戦ID：(\w{1,})\nLv(\d{1,3}) (.*)\nhttp.*/)
    if match
      @id = match[1]
      @level = match[2]
      @name = match[3]
    end
  end
end

client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

options = {
  track: "ID Lv50,Lv60,,Lv70,Lv75,Lv100#{ HELL ? ',Lv120' : '' }"
}
client.filter(options) do |object|
  return unless object.is_a?(Twitter::Tweet)
  r = ReliefRequest.new(object.text)
  if NAMES.include?(r.name)
    puts "Lv#{r.level} #{r.name} #{r.id}"
    `echo '#{r.id}' | pbcopy`
  end
end