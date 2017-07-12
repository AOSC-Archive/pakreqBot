#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

require 'logger'
require 'rbconfig'
require 'yaml'
require 'telegram/bot'
require_relative 'libs/database.rb'
require_relative 'libs/packages_api.rb'

class MultiDelegator
  def initialize(*targets)
    @targets = targets
  end

  def self.delegate(*methods)
    methods.each do |m|
      define_method(m) do |*args|
        @targets.map { |t| t.send(m, *args) }
      end
    end
    self
  end

  class <<self
    alias to new
  end
end

class PAKREQBOT
  def initialize(*targets)
    @targets = targets
  end

  def self.initialize_bot
    if RbConfig::CONFIG['target_os'] == 'mswin32'
      slash = "\\"
    else
      slash = "/"
    end
    # Initialize config
    if !(File.exist?("config.yml"))
      puts 'File "config.yml" not found, aborting...'
      puts 'Please run "rake mkconfig" before start the bot.'
      exit
    end
    if !(File.exist?("data#{slash}database.db"))
      puts 'Database not found, aborting...'
      puts 'Please run "rake mkconfig" before start the bot.'
      exit
    end
    configfile = File.open('config.yml')
    config = YAML.load(configfile)
    @@token = config["bot"]["token"]
    # Initialize Logger
    time = Time.new
    @@logger = Logger.new(STDOUT)
    if RbConfig::CONFIG['target_os'] == 'mswin32'
      slash = "\\"
    else
      slash = "/"
    end
    if config["bot"]["write_log_to_file"] == true
      Dir::mkdir("logs") if !(File.directory?("logs"))
      filename = "logs#{slash}bot_#{time.year}_#{time.yday}_#{time.hour}:#{time.min}:#{time.sec}.log"
      logfile = File.open(filename,"w+")
      @@logger = Logger.new MultiDelegator.delegate(:write, :close).to(STDOUT, logfile)
      @@logger.info("Logging to file \"#{filename}\"")
    end
    @@db = Database.db_open
    if @@db[1] == false
      @@logger.info("Cannot open database, aborting...")
      exit
    end
    @@logger.info("Bot started...")
  end

  def self.new_pakreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /pakreq@pakreqBot <package name> <description(optional)>",nil,nil
    end
    if (Packages_API.api_queue_pkg(message[1]) == false)
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database \"req\".")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          return "#{message[1]} already in the list.",nil,nil
        end
      end
      description = ""
      if message.length > 2
        for num in 2..message.length do
          description = description + "#{message[num]} "
        end
      else
        description = "<No description> "
      end
      time = Time.new
      status = Database.pkg_add(@@db,"req",message[1],description,1,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
      if status == false
        @@logger.error("Cannot add pakreq \"#{message[1]}\"")
      end
      notification = "A new pakreq:\n"
      notification = notification + "#{message[1]} - #{description}by @#{requester_username}"
      @@logger.info("A new pakreq: #{message[1]} - #{description}by @#{requester_username}")
      return "Successfully added #{message[1]} to the pending list.\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
    else
      return "#{message[1]} already in the source.",nil,nil
    end
  end

  def self.new_updreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /updreq@pakreqBot <package name> <description(optional)>",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      @@logger.error("Unable to read database \"req\".")
      return "Unable to read database, please contact the administrators.",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} already in the list.",nil,nil
      end
    end
    description = ""
    if message.length > 2
      for num in 2..message.length do
        description = description + "#{message[num]} "
      end
    else
      description = "<No description> "
    end
    time = Time.new
    status = Database.pkg_add(@@db,"req",message[1],description,2,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
    if status == false
      @@logger.error("Cannot add pakreq \"#{message[1]}\"")
      return "Failed to add a new pakareq. Please contact the administrators."
    end
    notification = "A new updreq:\n"
    notification = notification + "#{message[1]} - #{description}by @#{requester_username}"
    @@logger.info("A new updreq: #{message[1]} - #{description}by @#{requester_username}")
    return "Successfully added to the pending list.\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
  end

  def self.new_optreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /optreq@pakreqBot <package name> <description(optional)>",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      @@logger.error("Unable to read database \"req\".")
      return "Unable to read database, please contact the administrators.",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} already in the list.",nil,nil
      end
    end
    description = ""
    if message.length > 2
      for num in 2..message.length do
        description = description + "#{message[num]} "
      end
    else
      description = "<No description>"
    end
    time = Time.new
    status = Database.pkg_add(@@db,"req",message[1],description,3,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
    if status == false
      @@logger.error("Cannot add pakreq \"#{message[1]}\"")
    end
    notification = "A new optreq:\n"
    notification = notification + "#{message[1]} - #{description}By @#{requester_username}"
    @@logger.info("A new optreq: #{message[1]} - #{description}by @#{requester_username}")
    return "Successfully added to the list.\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
  end

  def self.list_pkg(message,table)
    message = message.split
    pkglist = Database.pkg_list(@@db,table)
    if pkglist[1] == false
      @@logger.error("Unable to read database.")
      return "Unable to read database, please contact the administrators."
    end
    if pkglist[0] == []
      case table
      when "req"
        return "No pending requests yet."
      when "done"
        return "No done requests yet."
      when "rejected"
        return "No rejected requests yet."
      end
    else
      if message.length < 2
        case table
        when "req"
          response = "Pending requests:\n"
        when "done"
          response = "Done requests:\n"
        when "rejected"
          response = "Rejected requests:\n"
        end
        pkglist[0].map do |arr|
          case arr[2]
          when 1
            category = "pakreq"
          when 2
            category = "updreq"
          when 3
            category = "optreq"
          end
          response = response + "#{arr[0]} (#{category}) : #{arr[1]}\n"
        end
        return response
      elsif message.length == 2
        pkglist[0].map do |arr|
          if arr[0] == message[1]
            if (arr[4] == nil)
              packager = "<Nobody>"
            else
              if arr[3] == nil
                packager = "ID: ##{arr[4]}"
              else
                packager = "@#{arr[3]}(#{arr[4]})"
              end
            end
            if arr[5] == nil
              requester = "ID: ##{arr[6]}"
            else
              requester = "@#{arr[5]}(#{arr[6]})"
            end
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            response = "Details of #{message[1]}:\n"
            response = response + "Package name: #{arr[0]}\n"
            response = response + "Description: #{arr[1]}\n"
            response = response + "Type: #{category}\n"
            response = response + "Packager: #{packager}\n"
            response = response + "Requeser: #{requester}\n"
            response = response + "Date: #{arr[7]}\n"
            if table == "req"
              if arr[8] == nil
                expected_finishing_date = "<Unknown>"
              else
                expected_finishing_date = "#{arr[8]}"
              end
              response = response + "Estimate date: #{expected_finishing_date}"
            end
            if table == "rejected"
              @@logger.info("\"#{arr[8]}\"")
              if (arr[8] == nil) or (arr[8] == "nil") or (arr[8] == "") or (arr[8] == " ")
                reason = "<Unknown>"
              else
                reason = arr[8]
              end
              response = response + "Reason: #{reason}"
            end
          end
        end
        return response
      end
    end
  end

  def self.claim_pkg(message,packager_username,packager_id)
    message = message.split
    if message.length < 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      if (pkglist[0] != nil) or (pkglist[0] != [])
        pkglist[0].map do |arr|
          if (arr[4] == nil) or (arr[4] == "nil") or (arr[4] == [])
            status = Database.pkg_claim(@@db,arr[0],packager_username,packager_id)
            if status == false
              @@logger.error("Failed to claim request #{arr[0]}.")
              return "Failed while claiming package, please contact the administrators.",nil,nil
            else
              case arr[2]
              when 1
                category = "pakreq"
              when 2
                category = "updreq"
              when 3
                category = "optreq"
              end
              if (packager_username == nil)
                packager = "ID: ##{packager_id}"
              else
                packager = "@#{packager_username}(#{packager_id})"
              end
              notification = "#{category} #{arr[0]} claimed by #{packager}."
              notification_requester = Array[arr[6],"Your "+notification]
              return "Successfully claimed request \"#{arr[0]}\"\n#{self.list_pkg("/list@pakreqBot #{arr[0]}","req")}",notification,notification_requester
            end
          end
        end
      else
        return "No unclaimed requests yet.",nil,nil
      end
      return "No unclaimed requests yet.",nil,nil
    elsif message.length > 2
      return "Invalid request. Usage: /claim@pakreqBot <package name(leave it blank if you want to claim a package randomly)>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          status = Database.pkg_claim(@@db,message[1],packager_username,packager_id)
          if status == false
            @@logger.error("Cannot claim request#{message[1]}")
            return "Failed to claim request #{message[1]}",nil,nil
          else
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            if (packager_username == nil)
              packager = "ID: ##{packager_id}"
            else
              packager = "@#{packager_username}(#{packager_id})"
            end
            notification = "#{category} #{message[1]} claimed by #{packager}."
            notification_requester = Array[arr[6],"Your "+notification]
            return "Successfully claimed #{message[1]}.\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
          end
        end
      end
      return "Invalid request.",nil,nil
    end
  end

  def self.unclaim_pkg(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /unclaim@pakreqBot <package name>",nil,nil
    elsif message.length == 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if arr[0] == message[1]
          if requester_id == arr[4]
            status = Database.pkg_unclaim(@@db,message[1])
            if status == false
              @@logger.error("Unable to unclaim request #{message[1]}")
              return "Unable to unclaim #{message[1]}, please contact the administrators.",nil,nil
            else
              case arr[2]
              when 1
                category = "pakreq"
              when 2
                category = "updreq"
              when 3
                category = "optreq"
              end
              if (packager_username == nil)
                packager = "ID: ##{packager_id}"
              else
                packager = "@#{packager_username}(#{packager_id})"
              end
              notification = "#{category} #{message[1]} unclaimed by #{packager}"
              notification_requester = Array[arr[6],"Your "+notification]
              return "Successfully unclaimed #{message[1]}\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
            end
          else
            return "Only the people who claimed this package can unclaim it.",nil,nil
          end
        end
      end
      return "Invalid request. Usage: /unclaim@pakreqBot <package name>",nil,nil
    end
  end

  def self.set_efd(message,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /setefd@pakreqBot <package name> <date(format:YYYY-mm-dd)>",nil,nil
    elsif message.length == 2
      return "Invalid request. Usage: /setefd@pakreqBot <package name> <date(format:YYYY-mm-dd)>",nil,nil
    elsif message.length > 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          if requester_id == arr[4]
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            efd = ""
            for num in 2..message.length do
              efd = efd + "#{message[num]} "
            end
            Database.pkg_set_efd(@@db,message[1],efd)
            notification = "#{category} #{arr[0]}'s estimated date set to #{efd}"
            notification_requester = Array[arr[6],"Your "+notification]
            return "Successfully set estimated date.\n#{self.list_pkg("/list@pakreqBot #{arr[0]}","req")}",notification,notification_requester
          else
            return "Only the one who claimed this package can set estimate date.",nil,nil
          end
        end
      end
      return "#{message[1]} not in the pending list.",nil,nil
    end
    return "Invalid request. Usage: /setefd@pakreqBot <package name> <date(format:YYYY-mm-dd)>",nil,nil
  end

  def self.mark_done(message,requester_id)
    message = message.split
    if message.length < 2
      return "Usage: /done@pakreqBot <package name>",nil,nil
    elsif message.length > 2
      return "Invalid request. Usage: /done@pakreqBot <package name>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if (message[1] == arr[0])
          if (requester_id == arr[4])
            status = Database.pkg_done(@@db,message[1],requester_id)
            if status == false
              @@logger.error("Unable to mark #{arr[0]} as done.")
              return "Unable to mark #{arr[0]} as done, please contact the administrators.",nil,nil
            end
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            if arr[3] == nil
              packager = "ID: ##{arr[4]}"
            else
              packager = "@#{arr[3]}(#{arr[4]})"
            end
            notification = "#{packager} marked #{category} #{message[1]} as DONE."
            notification_requester = Array[arr[6],"✅ Your "+notification]
            return "Marked #{message[1]} as DONE.\n#{self.list_pkg("/list@pakreqBot","req")}",notification,notification_requester
          else
            return "Only the people who claimed the package can mark it as done.",nil,nil
          end
        end
      end
      return "Invalid request.",nil,nil
    end
  end

  def self.reject_pkg(message,packager_username,packager_id)
    message = message.split
    if message.length < 2
      return "Usage: /reject@pakreqBot <package name> <reason(optional)>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators.",nil,nil
      end
      pkglist[0].map do |arr|
        if (message[1] == arr[0])
          reason = ""
          for num in 2..message.length
            reason = reason + "#{message[num]} "
          end
          status = Database.pkg_reject(@@db,message[1],packager_username,packager_id,reason)
          if status == true
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            if reason.split == []
              reason = "<Unknown>"
            end
            if packager_username == nil
              packager = "ID: #{arr[4]}"
            else
              packager = "@#{arr[3]}(#{arr[4]})"
            end
            notification = "#{category} #{message[1]} rejected by #{packager}.\n"
            notification = notification + "The reason is: #{reason}"
            notification_requester = Array[arr[6],"❌ Your "+notification]
            return "Successfully rejected #{message[1]}",notification,notification_requester
          else
            @@logger.error("Unable to reject #{message[1]}, please contact the administrators.")
            return "Unable to reject #{message[1]}, please contact the administrators.",nil,nil
          end
        end
      end
      return "Invalid request.",nil,nil
    end
  end

  def self.user_subscribe(user_id,user_username,chat_id)
    users = Database.user_list(@@db)
    if users[1] == false
      @@logger.error("Unable to read database.")
      return "Unable to read user database, please contact the administrators."
    end
    if (users[0] != nil) and (users[0] != [])
      users[0].map do |arr|
        if (user_id == arr[0]) and (arr[4] == 1)
          return "You already subscribed. Use /unsubscribe@pakreqBot to unsubscribe."
        elsif (user_id == arr[0]) and (arr[4] != 1)
          status = Database.user_set(@@db,"subscribe",user_id,true)
          if status == true
            return "Successfully subscribed."
          else
            @@logger.error("Unable to subscribe.")
            return "Failed to subscribe. Please contact the administrators."
          end
        elsif (user_id == arr[0]) and (arr[3] != 1)
          return "Because of the limitation of Telegram Bot API, bots cannot start chat with user directly. Please send /start to this bot."
        end
      end
    end
    if user_id != chat_id
      return "Because of the limitation of Telegram Bot API, bots cannot start chat with user directly. Please send /start to this bot."
    else
      status = Database.user_reg(@@db,user_id,user_username)
      if status == false
        @@logger.error("Unable to register user.")
        return "Failed to register user. Please contact the administrators."
      end
      status = Database.user_set(@@db,"session",user_id,true)
      if status == false
        @@logger.error("Unable to set session status.")
        return "Failed to set session status. Please contact the administrators."
      end
      status = Database.user_set(@@db,"subscribe",user_id,true)
      if status == true
        return "Successfully subscribed."
      else
        @@logger.error("Unable to subscribe.")
        return "Failed to subscribe. Please contact the administrators."
      end
    end
    return "Unknown error. Please contact the administrators."
  end

  def self.user_unsubscribe(user_id)
    users = Database.user_list(@@db)
    if users[1] == false
      @@logger.error("Unable to read database.")
      return "Unable to read user database, please contact the administrators."
    end
    users[0].map do |arr|
      if user_id == arr[0]
        status = Database.user_set(@@db,"subscribe",user_id,false)
        if status == true
          return "Successfully unsubscribed."
        else
          return "Unsubscribe failed. Please contact the administrators."
        end
      end
    end
    return "This account didn't subscribed."
  end

  def self.user_start(user_id,user_username,chat_id)
    if user_id == chat_id
      users = Database.user_list(@@db)
      if users[1] == false
        @@logger.error("Unable to read database.")
        return "Unable to read database, please contact the administrators."
      end
      if (users[0] != nil) and (users[0] != [])
        users[0].map do |arr|
          if arr[0] == arr[0]
            response = self.display_help
            return response
          else
            status = Database.user_reg(@@db,user_id,user_username)
            if status == false
              @@logger.error("Unable to register user.")
              return "Failed to register user. Please contact the administrators."
            end
            status = Database.user_set(@@db,"session",user_id,true)
            if status == false
              @@logger.error("Unable to set session status.")
              return "Failed to set session status. Please contact the administrators."
            end
            response = self.display_help
            return response
          end
        end
      else
        status = Database.user_reg(@@db,user_id,user_username)
        if status == false
          @@logger.error("Unable to register user.")
          return "Failed to register user. Please contact the administrators."
        end
        status = Database.user_set(@@db,"session",user_id,true)
        if status == false
          @@logger.error("Unable to set session status.")
          return "Failed to set session status. Please contact the administrators."
        end
        response = self.display_help
        return response
      end
    end
    response = self.display_help
    return response
  end

  def self.display_help
    response = "A bot that designed to execute Jelly.\n"
    response = response + "Command list:\n"
    response = response + "/pakreq@pakreqBot <package name> <description(optional)> - Add a new pakreq.\n"
    response = response + "/updreq@pakreqBot <package name> <description(optional)> - Add a new updreq.\n"
    response = response + "/optreq@pakreqBot <package name> <description(optional)> - Add a new optreq.\n"
    response = response + "/claim@pakreqBot <package name(leave it blank if you want to claim a package randomly)> - Claim a request.\n"
    response = response + "/unclaim@pakreqBot <package name> - Unclaim  a request.\n"
    response = response + "/done@pakreqBot <package name> - Mark a request as done.\n"
    response = response + "/set_efd@pakreqBot <package name> <date> - Set estimate date of a request.\n"
    response = response + "/reject@pakreqBot <package name> <reason(optional)> - Reject a request.\n"
    response = response + "/list@pakreqBot <package name(optional)>- List pending requests.\n"
    response = response + "/dlist@pakreqBot <package name(optional)>- List done requests.\n"
    response = response + "/rlist@pakreqBot <package name(optional)>- List rejected requests.\n"
    response = response + "/subscribe@pakreqBot - Subscribe.\n"
    response = response + "/unsubcribe@pakreqBot - Unsubscribe.\n"
    response = response + "/help@pakreqBot - Show this help message."
    return response
  end

  def self.message_parser(message)
    case message.text
    when /\/start/
      response = self.user_start(message.from.id,message.from.username,message.chat.id)
      return response,nil,nil
    when /\/help/
      response = self.display_help
      return response,nil,nil
    when /\/pakreq/
      response = self.new_pakreq(message.text,message.from.username,message.from.id)
      return response
    when /\/updreq/
      response = self.new_updreq(message.text,message.from.username,message.from.id)
      return response
    when /\/optreq/
      response = self.new_optreq(message.text,message.from.username,message.from.id)
      return response
    when /\/claim/
      response = self.claim_pkg(message.text,message.from.username,message.from.id)
      return response
    when /\/unclaim/
      response = self.unclaim_pkg(message.text,message.from.username,message.from.id)
      return response
    when /\/set_efd/
      response = self.set_efd(message.text,message.from.id)
      return response
    when /\/done/
      response = self.mark_done(message.text,message.from.id)
      return response
    when /\/reject/
      response = self.reject_pkg(message.text,message.from.username,message.from.id)
      return response
    when /\/list/
      response = self.list_pkg(message.text,"req")
      return response,nil,nil
    when /\/dlist/
      response = self.list_pkg(message.text,"done")
      return response,nil,nil
    when /\/rlist/
      response = self.list_pkg(message.text,"rejected")
      return response,nil,nil
    when /\/subscribe/
      response = self.user_subscribe(message.from.id,message.from.username,message.chat.id)
      return response,nil,nil
    when /\/unsubscribe/
      response = self.user_unsubscribe(message.from.id)
      return response,nil,nil
    when /\/stop/
      status = Database.user_set(@@db,"session",message.from.id,false)
      if status == false
        @@logger.error("Cannot set @#{message.from.username}(#{message.from.id})'s session status to false")
      end
      return nil,nil,nil
    else
      return nil,nil,nil
    end
  end

  def self.start
    self.initialize_bot
    Telegram::Bot::Client.run(@@token) do |bot|
      bot.listen do |message|
        @@logger.info("Got a message from @#{message.from.username}: #{message.text}")
        response = self.message_parser(message)
        if !(response[0] == nil) and !(response[0] == [])
          bot.api.send_message(chat_id: message.chat.id, text: response[0], reply_to_message_id: message.message_id)
        end
        if !(response[1] == nil) and !(response[1] == [])
          users = Database.user_list(@@db)
          if users[1] == false
            @@logger.error("Cannot load user list.")
          end
          if !(users[0] == []) and !(users[0] == nil)
            users[0].map do |arr|
              if !(response[1] == nil) and (arr[3] == 1) and (arr[4] == 1) and !(arr[0] == message.chat.id) and !(arr[0] == response[2][0])
                bot.api.send_message(chat_id: arr[0], text: response[1])
              end
            end
          end
        end
        if !(response[2] == nil) and !(response[2] == []) and !(response[2][0] == message.chat.id)
          bot.api.send_message(chat_id: response[2][0],text: response[2][1])
        end
      end
    end
  end
end

loop do
  PAKREQBOT.start
end
