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
    # Initialize Database (SQLibte3)
    @@db = SQLite3::Database.open("database.db")
  end

  def self.add_pkg(pkgname,homepage,requester)
    @@db.execute("INSERT INTO pakreq (pkgname,description,packager,requester)
                    VALUES (?,?,?,?)",[pkgname,homepage,nil,requester])
  end

  def self.update_packager_info(pkgname,packager)
    @@db.execute("UPDATE pakreq SET packager = ? WHERE pkgname = ?",[packager,pkgname])
  end

  def self.register_user(user_id)
    @@db.execute("INSERT INTO users (id,session,subscribe)
                    VALUES (?,?,?)",[user_id,0,0])
  end

  def self.unregister_user(user_id)
    @@db.execute("DELETE FROM users WHERE id=?",[user_id])
  end

  def self.update_user_subscribe_status(user_id,subscribe)
    if subscribe == true
      @@db.execute("UPDATE users SET subscribe = ? WHERE id = ?",[1,user_id])
    else
      @@db.execute("UPDATE users SET subscribe = ? WHERE id = ?",[0,user_id])
    end
  end

  def self.update_user_session_status(user_id,session_open)
    if session_open == true
      @@db.execute("UPDATE users SET session = ? WHERE id = ?",[1,user_id])
    else
      @@db.execute("UPDATE users SET session = ? WHERE id = ?",[0,user_id])
    end
  end

  def self.delete_request(pkgname)
    @@db.execute("DELETE FROM pakreq WHERE pkgname=?",[pkgname])
  end

  def self.new_pakreq(message,requester)
    message = message.split
    if message.length < 2
      return "使用方法： /pakreq@pakreqBot <包名> <描述（可選）>",nil
    end
    pkglist = @@db.execute("SELECT * FROM pakreq")
    pkglist.map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} 已在列隊中。",nil
      end
    end
    description = ""
    if message.length > 2
      for num in 2..message.length do
        description = description + "#{message[num]} "
      end
    else
      description = "描述爲空"
    end
    self.add_pkg(message[1],description,requester)
    notification = "有新的 pakreq：\n"
    notification = notification + "**#{message[1]}** - #{description}By @#{requester}"
    return "添加成功。\n#{self.list_pkg}",notification
  end

  def self.list_pkg
    pkglist = @@db.execute("SELECT * FROM pakreq")
    if pkglist == []
      return "沒有未完成的 pakreq。"
    else
      response = "以下爲所有未完成的 pakreq（包名: 描述 - 打包者 By 提交者）：\n"
      pkglist.map do |arr|
        if arr[2] == nil
          packager = "暫未認領"
        else
          packager = "@#{arr[2]}"
        end
        response = response + "#{arr[0]}: #{arr[1]}- #{packager} By @#{arr[3]}\n"
      end
      return response
    end
  end

  def self.claim_pkg(message,user)
    message = message.split
    if message.length < 2
      return "使用方法： /claim@pakreqBot <包名>",nil
    end
    if message.length > 2
      return "無效的請求，正確格式： /claim@pakreqBot <要認領的包名>",nil
    else
      pkglist = @@db.execute("SELECT * FROM pakreq")
      pkglist.map do |arr|
        if message[1] == arr[0]
          self.update_packager_info(message[1],user)
          notification = "#{message[1]} 已被 #{user} 認領"
          return "認領成功。\n#{self.list_pkg}",notification
        end
      end
      return "無效的請求，列隊中無此請求。",nil
    end
  end

  def self.mark_done(message)
    message = message.split(pattern=" ")
    if message.length < 2
      return "使用方法： /done@pakreqBot <包名>",nil
    end
    if message.length > 2
      return "無效的請求，正確格式： /done@pakreqBot <完成的包名>",nil
    else
      pkglist = @@db.execute("SELECT * FROM pakreq")
      pkglist.map do |arr|
        if message[1] == arr[0]
          self.delete_request(message[1])
          notification = "#{message[1]} 已完成"
          return "已標記完成。\n#{self.list_pkg}",notification
        end
      end
      return "無效的請求，列隊中無此請求。",nil
    end
  end

  def self.user_subscribe(user_id,chat_id)
    users = @@db.execute("SELECT * FROM users")
    users.map do |arr|
      if user_id == arr[0] and arr[2] == 1
        return "已經訂閱，無需重複訂閱。輸入 /unsubscribe@pakreqBot 以退訂"
      elsif user_id == arr[0] and arr[2] != 1
        self.update_user_subscribe_status(user_id,true)
        return "訂閱成功！"
      end
    end
    if user_id != chat_id
      return "由於 Telegram 限制，Bot 無法主動創建會話，請在開始會話後重新訂閱。"
    else
      self.register_user(user_id)
      self.update_user_subscribe_status(user_id,true)
      return "訂閱成功！"
    end
  end

  def self.user_unsubscribe(user_id)
    users = @@db.execute("SELECT * FROM users")
    users.map do |arr|
      if user_id == arr[0]
        self.update_user_subscribe_status(user_id,false)
        return "退訂成功！"
      end
    end
    return "此帳號並未訂閱。"
  end

  def self.user_start(user_id,chat_id)
    if user_id == chat_id
      users = @@db.execute("SELECT * FROM users")
      users.map do |arr|
        if arr[0] == arr[0]
          return "發送 /help 以查看幫助信息"
        else
          self.register_user(user_id)
          self.update_user_session_status(user_id,true)
          return "發送 /help 以查看幫助信息"
        end
      end
      self.register_user(user_id)
      self.update_user_session_status(user_id,true)
      return "發送 /help 以查看幫助信息"
    end
    return "發送 /help 以查看幫助信息"
  end

  def self.message_parser(message)
    case message.text
    when /\/start/
      response = self.user_start(message.from.id,message.chat.id)
      return response,nil
    when /\/help/
      response = "一個簡單的果凍處決 Bot\n"
      response = response + "命令列表：\n"
      response = response + "/pakreq@pakreqBot <包名> <描述> - 添加一個新的 pakreq\n"
      response = response + "/claim@pakreqBot <包名> - 認領這個 pakreq\n"
      response = response + "/done@pakreqBot <包名> - 標記這個 pakreq 已完成\n"
      response = response + "/list@pakreqBot - 列出所有未完成的 pakreq\n"
      response = response + "/subscribe@pakreqBot - 在 pakreq 狀態有更新時得到提醒（訂閱）\n"
      response = response + "/unsubcribe@pakreqBot - 關閉提醒（退訂）\n"
      response = response + "/help@pakreqBot - 查看此幫助信息"
      return response,nil
    when /\/pakreq/
      response = self.new_pakreq(message.text,message.from.username)
      return response
    when /\/list/
      response = self.list_pkg
      return response,nil
    when /\/claim/
      response = self.claim_pkg(message.text,message.from.username)
      return response
    when /\/done/
      response = self.mark_done(message.text)
      return response
    when /\/subscribe/
      response = self.user_subscribe(message.from.id,message.chat.id)
      return response,nil
    when /\/unsubscribe/
      response = self.user_unsubscribe(message.from.id)
      return response,nil
    when /\/stop/
      self.unregister_user(message.from.id)
      return response,nil
    else
      return nil,nil
    end
  end

  def self.start
    self.initialize_bot
    Telegram::Bot::Client.run(@@token) do |bot|
      bot.listen do |message|
        @@logger.info("Got a message from @#{message.from.username}: #{message.text}")
        response = self.message_parser(message)
        if response[0] != nil
          bot.api.send_message(chat_id: message.chat.id, text: response[0])
        end
        if response[1] != nil
          users = @@db.execute("SELECT * FROM users")
          users.map do |arr|
            if arr[1] == 1 and arr[2] == 1 and arr[0] != message.chat.id
              bot.api.send_message(chat_id: arr[0], text: response[1])
            end
          end
        end
      end
    end
  end
end

PAKREQBOT.start
