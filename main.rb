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
require 'sqlite3'

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
    # Initialize configure
    if !(File.exist?("config.yml"))
      puts 'File "config.yml" not found, aborting...'
      puts 'Please run "rake mkconfig" before start the bot.'
      exit
    end
    if !(File.exist?("database.db"))
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
    Dir::mkdir("logs") if !(File.directory?("logs"))
    if config["bot"]["write_log_to_file"] == true
      filename = "logs#{slash}bot_#{time.year}_#{time.yday}_#{time.hour}#{time.min}#{time.sec}.log"
      logfile = File.open(filename,"w+")
      @@logger = Logger.new MultiDelegator.delegate(:write, :close).to(STDOUT, logfile)
      @@logger.info("Logging to file \"#{filename}\"")
    end
    # Initialize Database (SQLite3)
    @@db = SQLite3::Database.open("database.db")
  end

  def self.add_pkg(pkgname,homepage)
    @@db.execute("INSERT INTO pakreq (pkgname,description,packager)
                   VALUES (?,?,?)",[pkgname,homepage,nil])
  end

  def self.update_packager_info(pkgname,packager)
    @@db.execute("UPDATE pakreq SET packager = ? WHERE pkgname = ?",[packager,pkgname])
  end

  def self.delete_request(pkgname)
    @@db.execute("DELETE FROM pakreq WHERE pkgname=?",[pkgname])
  end

  def self.new_pakreq(message)
    message = message.split(pattern=" ")
    pkglist = @@db.execute("SELECT * FROM pakreq")
    pkglist.map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} 已在列隊中。"
      end
    end
    response = ""
    for num in 2..message.length do
      response = response + "#{message[num]} "
    end
    self.add_pkg(message[1],response.chop)
    return "添加成功。\n#{self.list_pkg}"
  end

  def self.list_pkg
    pkglist = @@db.execute("SELECT * FROM pakreq")
    if pkglist == []
      return "沒有未完成的 pakreq。"
    else
      response = "以下爲所有未完成的 pakreq（包名: 描述 - 打包者）：\n"
      pkglist.map do |arr|
        if arr[2] == nil
          packager = "暫未認領"
        else
          packager = "@#{arr[2]}"
        end
        response = response + "#{arr[0]}: #{arr[1]}- #{packager}\n"
      end
      return response
    end
  end

  def self.claim_pkg(message,user)
    message = message.split(pattern=" ")
    if message.length > 2
      return "無效的請求，正確格式： `/claim@pakreqBot <要認領的包名>`"
    else
      pkglist = @@db.execute("SELECT * FROM pakreq")
      pkglist.map do |arr|
        if message[1] == arr[0]
          self.update_packager_info(message[1],user)
          return "認領成功。\n#{self.list_pkg}"
        end
      end
      return "無效的請求，列隊中無此請求。"
    end
  end

  def self.mark_done(message)
    message = message.split(pattern=" ")
    if message.length > 2
      return "無效的請求，正確格式： `/done@pakreqBot <完成的包名>`"
    else
      pkglist = @@db.execute("SELECT * FROM pakreq")
      pkglist.map do |arr|
        if message[1] == arr[0]
          self.delete_request(message[1])
          return "已標記完成。\n#{self.list_pkg}"
        end
      end
      return "無效的請求，列隊中無此請求。"
    end
  end

  def self.message_parser(message)
    case message.text
    when /\/start/
      return "發送 `/help` 以查看幫助信息"
    when /\/help/
      response = "一個簡單的果凍處決 Bot\n"
      response = response + "命令列表：\n"
      response = response + "`/pakreq@pakreqBot <包名> <描述>` - 添加一個新的 pakreq\n"
      response = response + "`/list@pakreqBot <包名>` - 列出所有未完成的 pakreq\n"
      response = response + "`/claim@pakreqBot <包名>` - 認領這個 pakreq\n"
      response = response + "`/done@pakreqBot <包名>` - 標記這個 pakreq 已完成\n"
      response = response + "`/help@pakreqBot` - 查看此幫助信息"
      return response
    when /\/pakreq/
      response = self.new_pakreq(message.text)
      return response
    when /\/list/
      response = self.list_pkg
      return response
    when /\/claim/
      response = self.claim_pkg(message.text,message.from.username)
      return response
    when /\/done/
      response = self.mark_done(message.text)
      return response
    end
  end

  def self.start
    self.initialize_bot
    Telegram::Bot::Client.run(@@token) do |bot|
      bot.listen do |message|
        @@logger.info("Got a message from @#{message.from.username}: #{message.text}")
        response = self.message_parser(message)
        if !(response == nil)
          bot.api.send_message(chat_id: message.chat.id, text: response, parse_mode: "markdown")
        end
      end
    end
  end
end

PAKREQBOT.start
