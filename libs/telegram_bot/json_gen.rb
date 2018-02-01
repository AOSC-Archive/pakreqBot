#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Generate JSON for Telegram bot API
# Author::      KayMW
# Copyright::   Copyright (c) 2017 KayMW <RedL0tus@users.noreply.github.com>
# License::     Do What The Fuck You Want To Public License, Version 2.

require 'json'
require 'rubygems'
require 'bundler/setup'

module Telegram_bot
  class Json_gen
    def initialize(*targets)
      # Make it static
      @targets = targets
    end

    def self.gen_json(*args)
      # Generate JSON for Telegram Bot API
      res = { }
      args.map do |arg|
        res = res.merge(arg)
      end
      return JSON.generate(res)
    end

    def self.html_esc(text)
      # Escape HTML
      res = text.to_s
      res = res.gsub(/\&/,"&amp;")
      res = res.gsub(/\</,"&lt;")
      res = res.gsub(/\>/,"&gt;")
      return res
    end
  end
end
