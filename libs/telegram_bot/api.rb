#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

require 'net/http'
require 'rubygems'
require 'bundler/setup'

module Telegram_bot
    class Api
        def initialize(token)
            while ((token != "") && (token != nil) && (token != []))
                @token = token
            @bot_api_base = "https://api.telegram.org/bot#{token}/"
                return true
            end
            return false
        end

        def get_updates(*offset)
            while ((offset != "") && (offset != nil) && (offset != []))
                uri = URI("#{@bot_api_base}getUpdates?offset=#{offset[0]}")
                return Net::HTTP.get(uri)
            end
            uri = URI("#{@bot_api_base}getUpdates")
            return Net::HTTP.get(uri)
        end

        def send_json(method,message_json)
            while ((method != "") && (method != nil) && (method != []) && (message_json != "") && (message_json != nil) && (message_json != []) && (message_json != ""))
                uri = URI("#{@bot_api_base}#{method}")
                req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
                req.body = message_json
                res = Net::HTTP.new(uri.hostname, uri.port)
                res.use_ssl = true
                return res.request(req).body
            end
            return false
        end
    end
end
