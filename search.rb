require 'twitter'
require 'dotenv'
require 'rbconfig'

Dotenv.load
NAMES = ENV['ONE_PUN_NAMES'].encode("UTF-8").split(',')
INCLUDE_120_HELL = ENV['INCLUDE_120_HELL'] == 'true' ? true : false
INCLUDE_100_HELL = ENV['INCLUDE_100_HELL'] == 'true' ? true : false

MAGUNA = [
  'ティアマト・マグナ',
  'コロッサス・マグナ',
  'リヴァイアサン・マグナ',
  'ユグドラシル・マグナ',
  'シュヴァリエ・マグナ',
  'セレスト・マグナ',
].freeze

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

def os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      :unknown
    end
  )
end

def copy_to_clipboard(r)
    puts "Lv#{r.level} #{r.name} #{r.id}"
    if os == :macosx
        `echo '#{r.id}' | pbcopy`
    elsif os == :windows
        `echo '#{r.id}' | clip`
    else
        puts "#{os} is not supported."
    end
end

client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

options = {
  track: "ID Lv50,Lv60,,Lv70,Lv75,Lv100#{ INCLUDE_120_HELL ? ',Lv120' : '' }"
}

client.filter(options) do |object|
  return unless object.is_a?(Twitter::Tweet)
  r = ReliefRequest.new(object.text)
  if NAMES.include?(r.name)
    if MAGUNA.include?(r.name)
        # マグナ系の場合はHLかどうか判定
        if r.level == "100"
            if INCLUDE_100_HELL
                copy_to_clipboard(r)
            else
                puts "reject --- Lv#{r.level} #{r.name} #{r.id}"
            end
        else
            copy_to_clipboard(r)
        end
    else
        copy_to_clipboard(r)
    end
  else
    puts "reject --- Lv#{r.level} #{r.name} #{r.id}"
  end
end
