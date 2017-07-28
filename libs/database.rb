#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

require 'sqlite3'
require 'rbconfig'

module Database
  def initialize(*targets)
    @targets = targets
  end

  def self.initialize_database
    if !(File::exist?("data"))
      Dir.mkdir("data")
    elsif !(File::directory?("data"))
      File.delete("data")
      Dir.mkdir("data")
    end
    if RbConfig::CONFIG['target_os'] == 'mswin32'
      slash = "\\"
    else
      slash = "/"
    end
    if !(File::exist?("data#{slash}base.db"))
      db = SQLite3::Database.new("data#{slash}database.db")
      db.execute("DROP TABLE IF EXISTS users")
      db.execute("DROP TABLE IF EXISTS pakreq")
      db.execute("DROP TABLE IF EXISTS pakreq_done")
      db.execute("DROP TABLE IF EXISTS pakreq_rejected")
      db.execute("DROP TABLE IF EXISTS version")
      db.execute("CREATE TABLE IF NOT EXISTS users(id,username,admin,session,subscribe,ban)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,expected_finishing_date)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq_done(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq_rejected(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,reason)")
      db.execute("CREATE TABLE IF NOT EXISTS version(db_scheme)")
      db.execute("INSERT INTO version(db_scheme)
                    VALUES (?)",["20170706"])
      return true
    end
    return false
  end

  def self.db_open
    if RbConfig::CONFIG['target_os'] == 'mswin32'
      slash = "\\"
    else
      slash = "/"
    end
    if (File.exist?("data#{slash}database.db"))
      db = SQLite3::Database.new("data#{slash}database.db")
      db.execute("CREATE TABLE IF NOT EXISTS users(id,username,admin,session,subscribe,ban)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,expected_finishing_date)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq_done(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date)")
      db.execute("CREATE TABLE IF NOT EXISTS pakreq_rejected(pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,reason)")
      return db,true
    end
    return nil,false
  end

  def self.pkg_list(db,table)
    if (db[1] == false) or (table == nil)
      return nil,false
    end
    db = db[0]
    case table
    when "req"
      pkginfo = db.execute("SELECT * FROM pakreq")
    when "done"
      pkginfo = db.execute("SELECT * FROM pakreq_done")
    when "rejected"
      pkginfo = db.execute("SELECT * FROM pakreq_rejected")
    else
      return nil,false
    end
    return pkginfo,true
  end

  def self.pkg_del(db,table,pkgname)
    if (db[1] == false) or (table == nil) or (pkgname == nil)
      return false
    end
    db = db[0]
    case table
    when "req"
      db.execute("DELETE FROM pakreq WHERE pkgname = ?",[pkgname])
    when "done"
      db.execute("DELETE FORM pakreq_done WHERE pkgname = ?",[pkgname])
    when "rejected"
      db.execute("DELETE FROM pakreq_rejected WHERE pkgname = ?",[pkgname])
    else
      return false
    end
    return true
  end

  def self.pkg_add(db,table,pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,expected_finishing_date,reason)
    if (db[1] == false) or (table == nil) or (pkgname == nil) or (category == nil)
      return false
    end
    db = db[0]
    case table
    when "req"
      db.execute("INSERT INTO pakreq (pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,expected_finishing_date)
                    VALUES (?,?,?,?,?,?,?,?,?)",[pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,expected_finishing_date])
    when "done"
      db.execute("INSERT INTO pakreq_done (pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date)
                    VALUES (?,?,?,?,?,?,?,?)",[pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date])
    when "rejected"
      db.execute("INSERT INTO pakreq_rejected (pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,reason)
                    VALUES (?,?,?,?,?,?,?,?,?)",[pkgname,description,category,packager_username,packager_id,requester_username,requester_id,date,reason])
    else
      return false
    end
    return true
  end

  def self.pkg_claim(db,pkgname,packager_username,packager_id)
    if (pkgname == nil) or (packager_username == nil) or (packager_id == nil) or (db[1] == false)
      return false
    end
    db = db[0]
    db.execute("UPDATE pakreq SET packager_username = ? WHERE pkgname = ?",[packager_username,pkgname])
    db.execute("UPDATE pakreq SET packager_id = ? WHERE pkgname = ?",[packager_id,pkgname])
    return true
  end

  def self.pkg_unclaim(db,pkgname)
    if (pkgname == nil) or (db[1] == false)
      return false
    end
    db = db[0]
    db.execute("UPDATE pakreq SET packager_username = ? WHERE pkgname = ?",[nil,pkgname])
    db.execute("UPDATE pakreq SET packager_id = ? WHERE pkgname = ?",[nil,pkgname])
    db.execute("UPDATE pakreq SET expected_finishing_date = ? WHERE pkgname = ?",[nil,pkgname])
    return true
  end

  def self.pkg_done(db,pkgname,requester_id)
    if (db[1] == false) or (pkgname == nil) or (requester_id == nil)
      return false
    end
    pakreq_list = self.pkg_list(db,"req")
    if pakreq_list[1] == false
      return false
    end
    pakreq_list[0].map do |arr|
      if arr[0] == pkgname and requester_id == arr[4]
        time = Time.new
        self.pkg_add(db,"done",arr[0],arr[1],arr[2],arr[3],arr[4],arr[5],arr[6],"#{time.getutc}",nil,nil)
        self.pkg_del(db,"req",pkgname)
        return true
      end
    end
    return false
  end

  def self.pkg_reject(db,pkgname,requester_username,requester_id,reason)
    if (db[1] == false) or (pkgname == nil) or (requester_username == nil) or (requester_id == nil)
      return false
    end
    pakreq_list = self.pkg_list(db,"req")
    if pakreq_list[1] == false
      return false
    end
    pakreq_list[0].map do |arr|
      if arr[0] == pkgname
        time = Time.new
        self.pkg_add(db,"rejected",arr[0],arr[1],arr[2],requester_username,requester_id,arr[5],arr[6],"#{time.getutc}",nil,reason)
        self.pkg_del(db,"req",pkgname)
        return true
      end
    end
    return false
  end

  def self.pkg_set_efd(db,pkgname,expected_finishing_date)
    if (db[1] == false) or (pkgname == nil)
      return false
    end
    if db[1] == false
      return false
    end
    db = db[0]
    db.execute("UPDATE pakreq SET expected_finishing_date = ? WHERE pkgname = ?",[expected_finishing_date,pkgname])
    return true
  end

  def self.user_list(db)
    if db[1] == false
      return nil,false
    end
    db = db[0]
    users = db.execute("SELECT * FROM users")
    if users == []
      return nil,true
    else
      return users,true
    end
  end

  def self.user_reg(db,id,username)
    if db[1] == false
      return false
    end
    users = self.user_list(db)
    db = db[0]
    if users[1] == false
      return false
    end
    users = users[0]
    if users != nil
      users.map do |arr|
        if arr[0] == id
          return true
        end
      end
    end
    db.execute("INSERT INTO users (id,username,admin,session,subscribe,ban)
                  VALUES (?,?,?,?,?,?)",[id,username,0,0,0,0])
    return true
  end

  def self.user_set(db,column,id,boolean)
    if (db[1] == false) or (column == nil) or (id == nil) or (boolean == nil)
      return false
    end
    users = self.user_list(db)
    db = db[0]
    if users[1] == false
      return false
    end
    users = users[0]
    if boolean == true
      value = 1
    else
      value = 0
    end
    users.map do |arr|
      if arr[0] == id
        case column
        when "admin"
          if arr[2] == value
            return true
          else
            db.execute("UPDATE users SET admin = ? WHERE id = ?",[value,id])
          end
        when "session"
          if arr[3] == value
            return true
          else
            db.execute("UPDATE users SET session = ? WHERE id = ?",[value,id])
          end
        when "subscribe"
          if arr[4] == value
            return true
          else
            db.execute("UPDATE users SET subscribe = ? WHERE id = ?",[value,id])
          end
        when "ban"
          if arr[4] == value
            return true
          else
            db.execute("UPDATE users SET ban = ? WHERE id = ?",[value,id])
          end
        else
          return false
        end
      end
    end
    return true
  end
end
