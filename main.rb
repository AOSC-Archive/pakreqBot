#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'sinatra'
require 'logger'
require 'rbconfig'
require 'telegram/bot'
require_relative 'libs/database.rb'
require_relative 'libs/packages_api.rb'
require_relative 'libs/api.rb'

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
      puts 'Please run "rake mkconfig" before starting the bot.'
      exit
    end
    if !(File.exist?("data#{slash}database.db"))
      puts 'Database not found, aborting...'
      puts 'Please run "rake mkconfig" before starting the bot.'
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
      @@logger.info("Logging to file \"#{filename}\"...")
    end
    @@db = Database.db_open
    if @@db[1] == false
      @@logger.info("Cannot open the database, aborting...")
      exit
    end
    @@logger.info("Bot started...")
  end

  def self.string_escape(message)
    response = message.to_s
    response = response.gsub(/\&/,"&amp;")
    response = response.gsub(/\</,"&lt;")
    response = response.gsub(/\>/,"&gt;")
    return response
  end

  def self.new_pakreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/pakreq@pakreqBot &lt;package&gt; [description]</code>.",nil,nil
    end
    if (Packages_API.api_queue_pkg(message[1]) == false)
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read the database \"req\".")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          pkgname = self.string_escape(message[1])
          return "#{pkgname} is <b>ALREADY</b> in the list.",nil,nil
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
      pkgname = self.string_escape(message[1])
      description = self.string_escape(description)
      if status == false
        @@logger.error("Cannot add pakreq \"#{pkgname}\"!")
      end
      notification = "A new <i>pakreq</i> is added to the list!\n"
      notification = notification + "<b>#{pkgname}</b> - #{description}by @#{requester_username}"
      @@logger.info("A new pakreq: #{pkgname} - #{description}by @#{requester_username}")
      return "Successfully added <b>#{pkgname}</b> to the <i>pakreq</i> listing.",notification,nil
    else
      pkgname = self.string_escape(message[1])
      return "#{pkgname} is already in the source.",nil,nil
    end
  end

  def self.new_updreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/updreq@pakreqBot &lt;package&gt; [description]</code>.",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      @@logger.error("Unable to read database \"req\".")
      return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        pkgname = self.string_escape(message[1])
        return "<b>#{pkgname}</b> is already in the list.",nil,nil
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
      @@logger.error("Cannot add pakreq \"#{message[1]}\"!")
      return "<b>Failed to add a new pakreq. Please contact the bot admin.</b>",nil,nil
    end
    description = self.string_escape(description)
    pkgname = self.string_escape(message[1])
    notification = "A new <i>updreq</i> is added to the list!\n"
    notification = notification + "<b>#{pkgname}</b> - #{description}by @#{requester_username}"
    @@logger.info("A new updreq: #{pkgname} - #{description}by @#{requester_username}")
    return "Successfully added to the <i>updreq</i> listing.",notification,nil
  end

  def self.new_optreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/optreq@pakreqBot &lt;package&gt; [description]</code>.",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      @@logger.error("Unable to read database \"req\".")
      return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        pkgname = self.string_escape(message[1])
        return "#{pkgname} is already in the list.",nil,nil
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
    pkgname = self.string_escape(message[1])
    description = self.string_escape(description)
    if status == false
      @@logger.error("Cannot add pakreq \"#{message[1]}\"!")
    end
    notification = "A new <i>optreq</i> is added to the list!\n"
    notification = notification + "<b>#{pkgname}</b> - #{description}By @#{requester_username}"
    @@logger.info("A new optreq: #{pkgname} - #{description}by @#{requester_username}")
    return "Successfully added to the <i>optreq</i> listing.",notification,nil
  end

  def self.list_pkg(message,table)
    message = message.split
    pkglist = Database.pkg_list(@@db,table)
    if pkglist[1] == false
      @@logger.error("Unable to read database.")
      return "<b>Error reading the database, please contact the bot admin.</b>"
    end
    if pkglist[0] == []
      case table
      when "req"
        return "<b>No pending requests found.</b>"
      when "done"
        return "<b>No done requests found.</b>"
      when "rejected"
        return "<b>No rejected requests found.</b>"
      end
      return "<b>Unknown error, please contact the bot admin.</b>"
    else
      if message.length < 2
        case table
        when "req"
          response = "Pending requests:\n\n"
        when "done"
          response = "Done requests:\n\n"
        when "rejected"
          response = "Rejected requests:\n\n"
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
          pkgname = self.string_escape(arr[0])
          description = self.string_escape(arr[1])
          response = response + "<b>#{pkgname}</b> (<i>#{category}</i>) : #{description}\n"
        end
        return response
      elsif message.length == 2
        response = ""
        pkglist[0].map do |arr|
          if arr[0] == message[1]
            if (arr[4] == nil)
              packager = "<Nobody>"
            else
              if arr[3] == nil
                packager = "ID: ##{arr[4]}"
              else
                packager = "@#{arr[3]} (#{arr[4]})"
              end
            end
            if arr[5] == nil
              requester = "ID: ##{arr[6]}"
            else
              requester = "@#{arr[5]} (#{arr[6]})"
            end
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            pkgname = self.string_escape(arr[0])
            description = self.string_escape(arr[1])
            category = self.string_escape(category)
            packager = self.string_escape(packager)
            requester = self.string_escape(requester)
            date = self.string_escape(arr[7])
            response = response + "Details of <b>#{pkgname}:</b>\n\n"
            response = response + "<b>Package name:</b> #{pkgname}\n"
            response = response + "<b>Description:</b> #{description}\n"
            response = response + "<b>Type:</b> <i>#{category}</i>\n"
            response = response + "<b>Packager:</b> #{packager}\n"
            response = response + "<b>Requestee:</b> #{requester}\n"
            response = response + "<b>Date:</b> #{date}\n"
            if table == "req"
              if arr[8] == nil
                eta = "<Unknown>"
              else
                eta = "#{arr[8]}"
              end
              eta = self.string_escape(eta)
              response = response + "<b>ETA:</b> #{eta}"
            end
            if table == "rejected"
              @@logger.info("\"#{arr[8]}\"")
              if (arr[8] == nil) or (arr[8] == "nil") or (arr[8] == "") or (arr[8] == " ")
                reason = "<Unknown>"
              else
                reason = arr[8]
              end
              reason = self.string_escape(reason)
              response = response + "<b>Reason:</b> #{reason}\n\n"
            end
          end
        end
        if (response != nil) and (response != "")
          return response
        else
          return "<b>Invalid request.</b>"
        end
        return "<b>Invalid request.</b>"
      else
        return "<b>Invalid request.</b>"
      end
      return "<b>Invalid request.</b>"
    end
    return "<b>Invalid request.</b>"
  end

  def self.claim_pkg(message,packager_username,packager_id)
    message = message.split
    if message.length < 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
      end
      if (pkglist[0] != nil) or (pkglist[0] != [])
        pkglist[0].map do |arr|
          if (arr[4] == nil) or (arr[4] == "nil") or (arr[4] == [])
            status = Database.pkg_claim(@@db,arr[0],packager_username,packager_id)
            if status == false
              @@logger.error("Failed to claim request #{arr[0]}.")
              return "<b>Error claiming the package, please contact the bot admin.</b>",nil,nil
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
                packager = "@#{packager_username} (#{packager_id})"
              end
              pkgname = self.string_escape(arr[0])
              category = self.string_escape(category)
              packager = self.string_escape(packager)
              notification = "<i>#{category}</i> <b>#{pkgname}</b> claimed by #{packager}."
              notification_requester = Array[arr[6],"Your "+notification]
              return "Successfully claimed request \"<b>#{pkgname}</b>\".\n\n#{self.list_pkg("/list@pakreqBot #{arr[0]}","req")}",notification,notification_requester
            end
          end
        end
      else
        return "<b>No unclaimed requests found.</b>",nil,nil
      end
      return "<b>No unclaimed requests found.</b>",nil,nil
    elsif message.length > 2
      return "<b>Invalid request. Usage:</b> <code>/claim [package]</code>.",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          status = Database.pkg_claim(@@db,message[1],packager_username,packager_id)
          if status == false
            pkgname = self.string_escape(message[1])
            @@logger.error("Cannot claim request#{pkgname}")
            return "Error claiming request <b>#{pkgname}</b>.",nil,nil
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
              packager = "@#{packager_username} (#{packager_id})"
            end
            pkgname = self.string_escape(message[1])
            category = self.string_escape(category)
            packager = self.string_escape(packager)
            notification = "<i>#{category}</i> <b>#{pkgname}</b> claimed by #{packager}."
            notification_requester = Array[arr[6],"Your "+notification]
            return "Successfully claimed <i>#{category}</i> <b>#{pkgname}</b>.\n\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
          end
        end
      end
      return "<b>Invalid request.</b>",nil,nil
    end
  end

  def self.unclaim_pkg(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/unclaim@pakreqBot &lt;package&gt;</code>.",nil,nil
    elsif message.length == 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
      end
      pkglist[0].map do |arr|
        if arr[0] == message[1]
          if requester_id == arr[4]
            status = Database.pkg_unclaim(@@db,message[1])
            if status == false
              pkgname = self.string_escape(message[1])
              @@logger.error("Unable to unclaim request #{message[1]}")
              return "Unable to unclaim <b>#{pkgname}</b>, please contact the bot admin.",nil,nil
            else
              case arr[2]
              when 1
                category = "pakreq"
              when 2
                category = "updreq"
              when 3
                category = "optreq"
              end
              if (requester_username == nil)
                packager = "ID: ##{packager_id}"
              else
                packager = "@#{requester_username} (#{requester_id})"
              end
              category = self.string_escape(category)
              pkgname = self.string_escape(message[1])
              packager = self.string_escape(packager)
              notification = "#{category} #{pkgname} unclaimed by #{packager}"
              notification_requester = Array[arr[6],"Your "+notification]
              return "Successfully unclaimed <i>#{category}</i> <b>#{message[1]}</b>.\n\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
            end
          else
            return "<b>ONLY</b> the people who claimed this package can unclaim it.",nil,nil
          end
        end
      end
      return "<b>Invalid request. Usage:</b> <code>/unclaim@pakreqBot &lt;package&gt;</code>.",nil,nil
    end
  end

  def self.set_eta(message,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/set_eta@pakreqBot &lt;package&gt; &lt;date(format:YYYY-mm-dd)&gt;</code>.",nil,nil
    elsif message.length == 2
      return "Invalid request. <b>Usage:</b> <code>/set_eta@pakreqBot &lt;package&gt; &lt;date(format:YYYY-mm-dd)&gt;</code>.",nil,nil
    elsif message.length > 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
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
            eta = ""
            for num in 2..message.length do
              eta = eta + "#{message[num]} "
            end
            Database.pkg_set_eta(@@db,message[1],eta)
            eta = self.string_escape(eta)
            category = self.string_escape(category)
            pkgname = self.string_escape(arr[0])
            notification = "#{category} #{pkgname}'s estimated date set to #{eta}"
            notification_requester = Array[arr[6],"Your "+notification]
            return "Successfully set estimated date to #{eta}.",notification,notification_requester
          else
            return "<b>ONLY</b> the one who claimed this package can set estimate date.",nil,nil
          end
        end
      end
      pkgname = self.string_escape(message[1])
      return "<b>#{pkgname}</b> isn't in the pending list.",nil,nil
    end
    return "<b>Invalid request. Usage:</b> <code>/seteta@pakreqBot &lt;package&gt; &lt;date(format:YYYY-mm-dd)&gt;</code>.",nil,nil
  end

  def self.mark_done(message,requester_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/done@pakreqBot &lt;package&gt;</code>.",nil,nil
    elsif message.length > 2
      return "<b>Invalid request. Usage:</b> <code>/done@pakreqBot &lt;package&gt;</code>.",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
      end
      pkglist[0].map do |arr|
        if (message[1] == arr[0])
          if (requester_id == arr[4])
            status = Database.pkg_done(@@db,message[1],requester_id)
            if status == false
              @@logger.error("Unable to mark #{arr[0]} as done.")
              pkgname = self.string_escape(arr[0])
              return "Unable to mark <b>#{pkgname}</b> as done, please contact the bot admin.",nil,nil
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
              packager = "@#{arr[3]} (#{arr[4]})"
            end
            packager = self.string_escape(packager)
            category = self.string_escape(category)
            pkgname = self.string_escape(message[1])
            notification = "<i>#{category}</i> <b>#{pkgname}</b> marked as <b>DONE by #{packager}.</b>"
            notification_requester = Array[arr[6],"✅ Your "+notification]
            return "✅ Marked <b>#{pkgname}</b> as <b>DONE</b>.",notification,notification_requester
          else
            return "<b>ONLY</b> the people who claimed the package can mark it as done.",nil,nil
          end
        end
      end
      return "<b>Invalid request.</b>",nil,nil
    end
  end

  def self.reject_pkg(message,packager_username,packager_id)
    message = message.split
    if message.length < 2
      return "<b>Usage:</b> <code>/reject@pakreqBot &lt;package&gt; [reason]</code>.",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>",nil,nil
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
              packager = "ID: #{packager_id}"
            else
              packager = "@#{packager_username} (#{packager_id})"
            end
            category = self.string_escape(category)
            pkgname = self.string_escape(message[1])
            packager = self.string_escape(packager)
            reason = self.string_escape(reason)
            notification = "<i>#{category}</i> <b>#{pkgname}</b> rejected by #{packager}.\n"
            notification = notification + "<b>The reason is:</b> #{reason}"
            notification_requester = Array[arr[6],"❌ Your "+notification]
            return "Successfully rejected <b>#{pkgname}</b>.",notification,notification_requester
          else
            @@logger.error("Unable to reject #{message[1]}, please contact the bot admin.")
            return "Unable to reject <b>#{message[1]}</b>, please contact the bot admin.",nil,nil
          end
        end
      end
      return "<b>Invalid request.</b>",nil,nil
    end
  end

  def self.user_subscribe(user_id,user_username,chat_id)
    users = Database.user_list(@@db)
    if users[1] == false
      @@logger.error("Unable to read database.")
      return "<b>Error read user database, please contact the bot admin.</b>"
    end
    if (users[0] != nil) and (users[0] != [])
      users[0].map do |arr|
        if (user_id == arr[0]) and (arr[4] == 1)
          return "You <b>already</b> subscribed. Use <code>/unsubscribe@pakreqBot</code> to unsubscribe."
        elsif (user_id == arr[0]) and (arr[4] != 1)
          status = Database.user_set(@@db,"subscribe",user_id,true)
          if status == true
            return "<b>Successfully subscribed.</b>"
          else
            @@logger.error("Unable to subscribe.")
            return "<b>Failed to subscribe. Please contact the bot admin.</b>"
          end
        elsif (user_id == arr[0]) and (arr[3] != 1)
          return "Due to the limitation of Telegram Bot API, bots <b>CANNOT</b> start chat with user directly. Please send <code>/start</code> to this bot."
        end
      end
    end
    if user_id != chat_id
      return "Due to the limitation of Telegram Bot API, bots <b>CANNOT</b> start chat with user directly. Please send <code>/start</code> to this bot."
    else
      status = Database.user_reg(@@db,user_id,user_username)
      if status == false
        @@logger.error("Unable to register user.")
        return "<b>Failed to register user. Please contact the bot admin.</b>"
      end
      status = Database.user_set(@@db,"session",user_id,true)
      if status == false
        @@logger.error("Unable to set session status.")
        return "<b>Failed to set session status. Please contact the bot admin.</b>"
      end
      status = Database.user_set(@@db,"subscribe",user_id,true)
      if status == true
        return "<b>Successfully subscribed.</b>"
      else
        @@logger.error("Unable to subscribe.")
        return "<b>Failed to subscribe. Please contact the bot admin.</b>"
      end
    end
    return "<b>Unknown error. Please contact the bot admin.</b>"
  end

  def self.user_unsubscribe(user_id)
    users = Database.user_list(@@db)
    if users[1] == false
      @@logger.error("Unable to read database.")
      return "<b>Error read user database, please contact the bot admin.</b>"
    end
    if users[0] != nil
      users[0].map do |arr|
        if user_id == arr[0]
          status = Database.user_set(@@db,"subscribe",user_id,false)
          if status == true
            return "<b>Successfully unsubscribed.</b>"
          else
            return "<b>Unsubscribe failed. Please contact the bot admin.</b>"
          end
        end
      end
    end
    return "<b>This account didn't subscribed.</b>"
  end

  def self.user_start(user_id,user_username,chat_id)
    if user_id == chat_id
      users = Database.user_list(@@db)
      if users[1] == false
        @@logger.error("Unable to read database.")
        return "<b>Error reading the database, please contact the bot admin.</b>"
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
              return "<b>Failed to register user. Please contact the bot admin.</b>"
            end
            status = Database.user_set(@@db,"session",user_id,true)
            if status == false
              @@logger.error("Unable to set session status.")
              return "<b>Failed to set session status. Please contact the bot admin.</b>"
            end
            response = self.display_help
            return response
          end
        end
      else
        status = Database.user_reg(@@db,user_id,user_username)
        if status == false
          @@logger.error("Unable to register user.")
          return "<b>Failed to register user. Please contact the bot admin.</b>"
        end
        status = Database.user_set(@@db,"session",user_id,true)
        if status == false
          @@logger.error("Unable to set session status.")
          return "<b>Failed to set session status. Please contact the bot admin.</b>"
        end
        response = self.display_help
        return response
      end
    end
    response = self.display_help
    return response
  end

  def self.display_help
    response = "A bot designed to <b>EXECUTE</b> Jelly.\n\n"
    response = response + "<b>Command list:</b>\n"
    response = response + "<code>/pakreq &lt;package&gt; [description]</code> - Add a new pakreq.\n"
    response = response + "<code>/updreq &lt;package&gt; [description]</code> - Add a new updreq.\n"
    response = response + "<code>/optreq &lt;package&gt; [description]</code> - Add a new optreq.\n"
    response = response + "<code>/claim [package]</code> - Claim a request, leave <code>[package]</code> for a random claim.\n"
    response = response + "<code>/unclaim &lt;package&gt;</code> - Unclaim  a request.\n"
    response = response + "<code>/done &lt;package&gt;</code> - Mark a request as done.\n"
    response = response + "<code>/set_eta &lt;package&gt; &lt;date(format:YYYY-mm-dd)&gt;</code> - Set an estimated date for a request.\n"
    response = response + "<code>/reject &lt;package&gt; [reason]</code> - Reject a request.\n"
    response = response + "<code>/list [package]</code> - List pending requests.\n"
    response = response + "<code>/dlist [package]</code> - List done requests.\n"
    response = response + "<code>/rlist [package]</code> - List rejected requests.\n"
    response = response + "<code>/subscribe</code> - Subscribe.\n"
    response = response + "<code>/unsubcribe</code> - Unsubscribe.\n"
    response = response + "<code>/help</code> - Show this help message."
    return response
  end

  def self.message_parser(message)
    case message.text
    when /^\/start$|^\/start@pakreqBot$/
      response = self.user_start(message.from.id,message.from.username,message.chat.id)
      return response,nil,nil
    when /^\/help$|^\/help@pakreqBot$/
      response = self.display_help
      return response,nil,nil
    when /^\/pakreq$|^\/pakreq\s(.*)|^\/pakreq@pakreqBot\s(.*)|^\/pakreq@pakreqBot$/
      response = self.new_pakreq(message.text,message.from.username,message.from.id)
      return response
    when /^\/updreq$|^\/updreq\s(.*)|^\/updreq@pakreqBot\s(.*)|^\/updreq@pakreqBot$/
      response = self.new_updreq(message.text,message.from.username,message.from.id)
      return response
    when /^\/optreq$|^\/optreq\s(.*)|^\/optreq@pakreqBot\s(.*)|^\/optreq@pakreqBot$/
      response = self.new_optreq(message.text,message.from.username,message.from.id)
      return response
    when /^\/claim$|^\/claim\s(.*)|^\/claim@pakreqBot\s(.*)|^\/claim@pakreqBot$/
      response = self.claim_pkg(message.text,message.from.username,message.from.id)
      return response
    when /^\/unclaim$|^\/unclaim\s(.*)|^\/unclaim@pakreqBot\s(.*)|^\/unclaim@pakreqBot$/
      response = self.unclaim_pkg(message.text,message.from.username,message.from.id)
      return response
    when /^\/set_eta$|^\/set_eta\s(.*)|^\/set_eta@pakreqBot\s(.*)|^\/set_eta@pakreqBot$/
      response = self.set_eta(message.text,message.from.id)
      return response
    when /^\/done$|^\/done\s(.*)|^\/done@pakreqBot\s(.*)|^\/done@pakreqBot$/
      response = self.mark_done(message.text,message.from.id)
      return response
    when /^\/reject$|^\/reject\s(.*)|^\/reject@pakreqBot\s(.*)|^\/reject@pakreqBot$/
      response = self.reject_pkg(message.text,message.from.username,message.from.id)
      return response
    when /^\/list$|^\/list\s(.*)|^\/list@pakreqBot\s(.*)|^\/list@pakreqBot$/
      response = self.list_pkg(message.text,"req")
      return response,nil,nil
    when /^\/dlist$|^\/dlist\s(.*)|^\/dlist@pakreqBot\s(.*)|^\/dlist@pakreqBot$/
      response = self.list_pkg(message.text,"done")
      return response,nil,nil
    when /^\/rlist$|^\/rlist\s(.*)|^\/rlist@pakreqBot\s(.*)|^\/rlist@pakreqBot$/
      response = self.list_pkg(message.text,"rejected")
      return response,nil,nil
    when /^\/subscribe$|^\/subscribe\s(.*)|^\/subscribe@pakreqBot\s(.*)|^\/subscribe@pakreqBot$/
      response = self.user_subscribe(message.from.id,message.from.username,message.chat.id)
      return response,nil,nil
    when /^\/unsubscribe$|^\/unsubscribe\s(.*)|^\/unsubscribe@pakreqBot\s(.*)|^\/unsubscribe@pakreqBot$/
      response = self.user_unsubscribe(message.from.id)
      return response,nil,nil
    when /^\/stop$|^\/stop@pakreqBot$/
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
        if !(response[0] == nil) and !(response[0] == "")
          @@logger.info("Response length: #{response[0].length}")
        end
        if !(response[0] == nil) and !(response[0] == []) and (response[0] != nil) and (response[0] != []) and (response[0].length < 4000)
          bot.api.send_message(chat_id: message.chat.id, text: response[0], reply_to_message_id: message.message_id, parse_mode: "html")
        end
        if !(response[1] == nil) and !(response[1] == []) and (response[1] != nil) and (response[1] != [])
          users = Database.user_list(@@db)
          if users[1] == false
            @@logger.error("Cannot load user list.")
          end
          if !(users[0] == []) and !(users[0] == nil) and (users[0] != []) and (users[0] != nil)
            users[0].map do |arr|
              if (response[2] != nil) and (response[2] != [])
                if (response[1] != nil) and (arr[3] == 1) and (arr[4] == 1) and !(arr[0] == message.chat.id) and !(arr[0] == response[2][0])
                  bot.api.send_message(chat_id: arr[0], text: response[1], parse_mode: "html")
                end
              else
                if (response[1] != nil) and (arr[3] == 1) and (arr[4] == 1) and !(arr[0] == message.chat.id)
                  bot.api.send_message(chat_id: arr[0], text: response[1], parse_mode: "html")
                end
              end
              if !(response[2] == nil) and !(response[2] == []) and (response[2][0] == arr[0]) and !(response[2][0] == message.chat.id) and (arr[3] == 1)
                bot.api.send_message(chat_id: response[2][0],text: response[2][1], parse_mode: "html")
              end
            end
          end
        end
      end
    end
  end
end

loop do
  Thread.new{ PAKREQAPI.run! }
  PAKREQBOT.start
end
