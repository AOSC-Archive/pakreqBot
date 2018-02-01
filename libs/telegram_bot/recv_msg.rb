#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Processor of received messages
# Author::      KayMW
# Copyright::   Copyright (c) 2017 KayMW <RedL0tus@users.noreply.github.com>
# License::     Do What The Fuck You Want To Public License, Version 2.

require 'json'
require 'rubygems'
require 'bundler/setup'

module Telegram_bot
  class Recv_msg
    @reponse = nil

    def initialize(response)
      @response = response
    end

    def parse()
      while (@response != "") && (@response != nil) && (@response != [])
        return JSON.parse(@response)
      end
      return false
    end
  end
end