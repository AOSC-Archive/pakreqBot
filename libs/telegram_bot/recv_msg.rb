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