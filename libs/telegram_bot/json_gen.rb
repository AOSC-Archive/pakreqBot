#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

require 'json'
require 'rubygems'
require 'bundler/setup'

module Telegram_bot
    class Json_gen
        def initialize(*targets)
            @targets = targets
        end

        def self.gen_json(*args)
            res = { }
            args.map do |arg|
                res = res.merge(arg)
            end
            return JSON.generate(res)
        end

        def self.html_esc(text)
            res = text.to_s
            res = res.gsub(/\&/,"&amp;")
            res = res.gsub(/\</,"&lt;")
            res = res.gsub(/\>/,"&gt;")
            return res
        end
    end
end
