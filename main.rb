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
    Dir::mkdir("logs") if !(File.directory?("logs"))
    if config["bot"]["write_log_to_file"] == true
      filename = "logs#{slash}bot_#{time.year}_#{time.yday}_#{time.hour}#{time.min}#{time.sec}.log"
      logfile = File.open(filename,"w+")
      @@logger = Logger.new MultiDelegator.delegate(:write, :close).to(STDOUT, logfile)
      @@logger.info("Logging to file \"#{filename}\"")
    end
    @@db = Database.db_open
    if @@db[1] == false
      @@logger.info("Cannot open database, aborting...")
      exit
    end
  end

  def self.new_pakreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /pakreq@pakreqBot <包名> <描述（可選）>",nil,nil
    end
    if (Packages_API.api_queue_pkg(message[1]) == false)
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "數據庫讀取失敗，請聯繫 @TheSaltedFish",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          return "#{message[1]} 已在列隊中。",nil,nil
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
      time = Time.new
      status = Database.pkg_add(@@db,"req",message[1],description,1,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
      if status == false
        @@logger.error("Cannot add pakreq \"#{message[1]}\"")
      end
      notification = "有新的 pakreq：\n"
      notification = notification + "#{message[1]} - #{description}By @#{requester_username}"
      return "添加成功。\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
    else
      return "源中已存在此包，無需重新請求。",nil,nil
    end
  end

  def self.new_updreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /updreq@pakreqBot <包名> <描述（可選）>",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      return "數據庫讀取失敗，請聯繫 @TheSaltedFish",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} 已在列隊中。",nil,nil
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
    time = Time.new
    status = Database.pkg_add(@@db,"req",message[1],description,2,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
    if status == false
      @@logger.error("Cannot add pakreq \"#{message[1]}\"")
    end
    notification = "有新的 updreq：\n"
    notification = notification + "#{message[1]} - #{description}By @#{requester_username}"
    return "添加成功。\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
  end

  def self.new_optreq(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /optreq@pakreqBot <包名> <描述（可選）>",nil,nil
    end
    pkglist = Database.pkg_list(@@db,"req")
    if pkglist[1] == false
      return "數據庫讀取失敗，請聯繫 @TheSaltedFish",nil,nil
    end
    pkglist[0].map do |arr|
      if message[1] == arr[0]
        return "#{message[1]} 已在列隊中。",nil,nil
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
    time = Time.new
    status = Database.pkg_add(@@db,"req",message[1],description,3,nil,nil,requester_username,requester_id,"#{time.getutc}",nil,nil)
    if status == false
      @@logger.error("Cannot add pakreq \"#{message[1]}\"")
    end
    notification = "有新的 optreq：\n"
    notification = notification + "#{message[1]} - #{description}By @#{requester_username}"
    return "添加成功。\n#{self.list_pkg("/list@pakreqBot","req")}",notification,nil
  end

  def self.list_pkg(message,table)
    message = message.split
    pkglist = Database.pkg_list(@@db,table)
    if pkglist[1] == false
      return "數據庫讀取失敗，請聯繫 @TheSaltedFish"
    end
    if pkglist[0] == []
      case table
      when "req"
        return "沒有未完成的请求。"
      when "done"
        return "没有已完成的请求。"
      when "rejected"
        return "没有已拒绝的请求。"
      end
    else
      if message.length < 2
        case table
        when "req"
          response = "以下爲所有未完成的請求（包名（類型）: 描述）：\n"
        when "done"
          response = "以下为所有已完成的请求（包名（類型）：描述）：\n"
        when "rejected"
          response = "以下为所有已拒绝的请求（包名（類型）：描述）：\n"
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
              packager = "暫未認領"
            else
              if arr[3] == nil
                packager = "ID: ##{arr[4]}"
              else
                packager = "@#{arr[5]}(#{arr[4]})"
              end
            end
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            response = "以下爲請求 #{message[1]} 的具體信息：\n"
            response = response + "包名： #{arr[0]}\n"
            response = response + "描述： #{arr[1]}\n"
            response = response + "類型： #{category}\n"
            response = response + "打包者： #{packager}\n"
            response = response + "提交者： @#{arr[5]}(#{arr[6]})\n"
            if table == "req"
              date = "提交日期"
            else
              date = "處理日期"
            end
            response = response + "#{date}： #{arr[7]}\n"
            if table == "req"
              if arr[8] == nil
                expected_finishing_date = "未知"
              else
                expected_finishing_date = "#{arr[8]}"
              end
              response = response + "預計完成日期： #{expected_finishing_date}"
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
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
      end
      if (pkglist[0] != nil) or (pkglist[0] != [])
        pkglist[0].map do |arr|
          if (arr[4] == nil) or (arr[4] == "nil") or (arr[4] == [])
            status = Database.pkg_claim(@@db,arr[0],packager_username,packager_id)
            if status == false
              return "認領失敗，請聯繫 @TheSaltedFish",nil,nil
            else
              case arr[2]
              when 1
                category = "pakreq"
              when 2
                category = "updreq"
              when 3
                category = "optreq"
              end
              notification = "#{category} #{arr[0]} 已被 @#{packager_username} 認領。"
              notification_requester = Array[arr[6],"您的 "+notification]
              return "認領成功。\n#{self.list_pkg("/list@pakreqBot #{arr[0]}","req")}",notification,notification_requester
            end
          end
        end
      else
        return "沒有未被認領的 pakreq。",nil,nil
      end
      return "沒有未被認領的 pakreq。",nil,nil
    elsif message.length > 2
      return "無效的請求，正確格式： /claim@pakreqBot <要認領的包名>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
      end
      pkglist[0].map do |arr|
        if message[1] == arr[0]
          status = Database.pkg_claim(@@db,message[1],packager_username,packager_id)
          if status == false
            return "認領失敗，請聯繫 @TheSaltedFish",nil,nil
          else
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            notification = "#{category} #{message[1]} 已被 @#{packager_username} 認領。"
            notification_requester = Array[arr[6],"您的 "+notification]
            return "認領成功。\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
          end
        end
      end
      return "無效的請求，列隊中無此請求。",nil,nil
    end
  end

  def self.unclaim_pkg(message,requester_username,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /unclaim@pakreqBot <包名>",nil,nil
    elsif message.length == 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
      end
      pkglist[0].map do |arr|
        if arr[0] == message[1]
          if requester_id == arr[4]
            status = Database.pkg_unclaim(@@db,message[1])
            if status == false
              return "取消認領失敗，請聯繫 @TheSaltedFish",nil,nil
            else
              case arr[2]
              when 1
                category = "pakreq"
              when 2
                category = "updreq"
              when 3
                category = "optreq"
              end
              notification = "#{category} #{message[1]} 被 @#{requester_username} 取消了認領。"
              notification_requester = Array[arr[6],"您的 "+notification]
              return "取消認領成功。\n#{self.list_pkg("/list@pakreqBot #{message[1]}","req")}",notification,notification_requester
            end
          else
            return "只能由認領了此包的打包者取消認領。",nil,nil
          end
        end
      end
      return "無效的請求，使用方法： /unclaim@pakreqBot <包名>",nil,nil
    end
  end

  def self.set_efd(message,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /setefd@pakreqBot <包名> <日期（格式：YYYY-mm-dd）>",nil,nil
    elsif message.length == 2
      return "無效的請求，正確格式： /setefd@pakreqBot <包名> <日期（格式：YYYY-mm-dd）>",nil,nil
    elsif message.length > 2
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
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
            notification = "#{category} #{arr[0]} 預計將在 #{efd}完成。"
            notification_requester = Array[arr[6],"您的 "+notification]
            return "設置成功。\n#{self.list_pkg("/list@pakreqBot #{arr[0]}","req")}",notification,notification_requester
          else
            return "只能由對應的打包者設置預計完成的時間。",nil,nil
          end
        end
      end
      return "列隊中無此請求。",nil,nil
    end
    return "無效的請求，正確格式： /setefd@pakreqBot <包名> <日期（格式：YYYY-mm-dd HH:MM:SS +HHMM）>",nil,nil
  end

  def self.mark_done(message,requester_id)
    message = message.split
    if message.length < 2
      return "使用方法： /done@pakreqBot <包名>",nil,nil
    elsif message.length > 2
      return "無效的請求，正確格式： /done@pakreqBot <完成的包名>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
      end
      pkglist[0].map do |arr|
        if (message[1] == arr[0])
          if (requester_id == arr[4])
            status = Database.pkg_done(@@db,message[1],requester_id)
            if status == false
              return "標記完成失敗，請聯繫 @TheSaltedFish",nil,nil
            end
            case arr[2]
            when 1
              category = "pakreq"
            when 2
              category = "updreq"
            when 3
              category = "optreq"
            end
            notification = "#{category} #{message[1]} 已完成"
            notification_requester = Array[arr[6],notification]
            return "已標記完成。\n#{self.list_pkg("/list@pakreqBot","req")}",notification,notification_requester
          else
            return "只有對應的打包者才能標記完成。",nil,nil
          end
        end
      end
      return "無效的請求，列隊中無此請求。",nil,nil
    end
  end

  def self.reject_pkg(message,packager_username,packager_id)
    message = message.split
    if message.length < 2
      return "使用方法：/reject@pakreqBot <包名> <理由>",nil,nil
    else
      pkglist = Database.pkg_list(@@db,"req")
      if pkglist[1] == false
        return "無法讀取數據庫，請聯繫 @TheSaltedFish",nil,nil
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
              reason = "未知"
            end
            notification = "#{category} #{message[1]} 已被 @#{packager_username} 拒絕。\n"
            notification = notification + "理由是： #{reason}"
            notification_requester = Array[arr[6],"您的 "+notification]
            return "已成功拒絕。",notification,notification_requester
          else
            return "未能成功標記拒絕，請聯繫 @TheSaltedFish",nil,nil
          end
        end
      end
      return "列隊中無此請求",nil,nil
    end
  end

  def self.user_subscribe(user_id,user_username,chat_id)
    users = Database.user_list(@@db)
    if users[1] == false
      return "無法讀取用戶數據庫，請聯繫 @TheSaltedFish"
    end
    if (users[0] != nil) and (users[0] != [])
      users[0].map do |arr|
        if (user_id == arr[0]) and (arr[4] == 1)
          return "已經訂閱，無需重複訂閱。輸入 /unsubscribe@pakreqBot 以退訂"
        elsif (user_id == arr[0]) and (arr[4] != 1)
          status = Database.user_set(@@db,"subscribe",user_id,true)
          if status == true
            return "訂閱成功！"
          else
            return "訂閱失敗，請聯繫 @TheSaltedFish"
          end
        elsif (user_id == arr[0]) and (arr[3] != 1)
          return "由於 Telegram 限制，Bot 無法主動創建會話，請先與 Bot 創建會話並重試。如果已創建會話，請在會話中輸入 /start 以創建記錄。"
        end
      end
    else
      if user_id != chat_id
        return "由於 Telegram 限制，Bot 無法主動創建會話，請先與本 Bot 創建會話並重試。如果已創建會話，請在會話中輸入 /start 以創建記錄。"
      else
        status = Database.user_reg(@@db,user_id,user_username)
        if status == false
          return "用戶登記失敗，請聯繫 @TheSaltedFish"
        end
        status = Database.user_set(@@db,"session",user_id,true)
        if status == false
          return "用戶會話狀態登記失敗，請聯繫 @TheSaltedFish"
        end
        status = Database.user_set(@@db,"subscribe",user_id,true)
        if status == true
          return "訂閱成功！"
        else
          return "訂閱失敗，請聯繫 @TheSaltedFish"
        end
      end
    end
  end

  def self.user_unsubscribe(user_id)
    users = Database.user_list(@@db)
    if users[1] == false
      return "無法讀取用戶數據庫，請聯繫 @TheSaltedFish"
    end
    users[0].map do |arr|
      if user_id == arr[0]
        status = Database.user_set(@@db,"subscribe",user_id,false)
        if status == true
          return "退訂成功！"
        else
          return "退訂失敗，請聯繫 @TheSaltedFish"
        end
      end
    end
    return "此帳號並未訂閱。"
  end

  def self.user_start(user_id,user_username,chat_id)
    if user_id == chat_id
      users = Database.user_list(@@db)
      if users[1] == false
        return "無法讀取用戶數據庫，請聯繫 @TheSaltedFish"
      end
      if (users[0] != nil) and (users[0] != [])
        users[0].map do |arr|
          if arr[0] == arr[0]
            return "發送 /help 以查看幫助信息"
          else
            status = Database.user_reg(@@db,user_id,user_username)
            if status == false
              return "用戶登記失敗，請聯繫 @TheSaltedFish"
            end
            status = Database.user_set(@@db,"session",user_id,true)
            if status == false
              return "用戶會話狀態登記失敗，請聯繫 @TheSaltedFish"
            end
            return "發送 /help 以查看幫助信息"
          end
        end
      else
        status = Database.user_reg(@@db,user_id,user_username)
        if status == false
          return "用戶登記失敗，請聯繫 @TheSaltedFish"
        end
        status = Database.user_set(@@db,"session",user_id,true)
        if status == false
          return "用戶會話狀態登記失敗，請聯繫 @TheSaltedFish"
        end
        return "發送 /help 以查看幫助信息"
      end
    end
    return "發送 /help 以查看幫助信息"
  end

  def self.message_parser(message)
    case message.text
    when /\/start/
      response = self.user_start(message.from.id,message.from.username,message.chat.id)
      return response,nil
    when /\/help/
      response = "果凍處決特化型 Bot\n"
      response = response + "命令列表：\n"
      response = response + "/pakreq@pakreqBot <包名> <描述> - 添加一個新的 pakreq。\n"
      response = response + "/updreq@pakreqBot <包名> <描述> - 添加一個新的 updreq。\n"
      response = response + "/optreq@pakreqBot <包名> <描述> - 添加一個新的 optreq。\n"
      response = response + "/claim@pakreqBot <包名> - 認領一個請求（或不加參數以隨便認領一個請求）。\n"
      response = response + "/unclaim@pakreqBot <包名> - 取消認領一個請求。\n"
      response = response + "/done@pakreqBot <包名> - 標記這個 pakreq 已完成，必須由打包者執行。\n"
      response = response + "/set_efd@pakreqBot <包名> <日期> - 設置預期的完成日期（其實 Bot 並不會檢查是否遵守格式 XD）。\n"
      response = response + "/reject@pakreqBot <包名> <原因> - 拒絕一個請求。\n"
      response = response + "/list@pakreqBot <包名（可選）>- 列出所有未完成的請求（加上包名即顯示請求具體信息）\n"
      response = response + "/dlist@pakreqBot <包名（可選）>- 列出所有已完成的請求（加上包名即顯示請求具體信息）\n"
      response = response + "/rlist@pakreqBot <包名（可選）>- 列出所有已拒絕的請求（加上包名即顯示請求具體信息）\n"
      response = response + "/subscribe@pakreqBot - 在 pakreq 狀態有更新時得到提醒（訂閱）\n"
      response = response + "/unsubcribe@pakreqBot - 關閉提醒（退訂）\n"
      response = response + "/help@pakreqBot - 查看此幫助信息"
      return response,nil
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
        if (response[0] != nil) and (response[0] != [])
          bot.api.send_message(chat_id: message.chat.id, text: response[0], reply_to_message_id: message.message_id)
        end
        if (response[1] != nil) and (response[1] != [])
          users = Database.user_list(@@db)
          if users[1] == false
            @@logger.error("Cannot load user list.")
          end
          if (users[0] != []) and (users[0] != nil)
            users[0].map do |arr|
              if (response[1] != nil) and (arr[3] == 1) and (arr[4] == 1) and (arr[0] != message.chat.id) and (arr[0] != response[2][0])
                bot.api.send_message(chat_id: arr[0], text: response[1])
              end
            end
          end
        end
        if (response[2] != nil) and (response[2] != []) and (response[2][0] != message.chat.id)
          bot.api.send_message(chat_id: response[2][0],text: response[2][1])
        end
      end
    end
  end
end

PAKREQBOT.start
