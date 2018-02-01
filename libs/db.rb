#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# SQLite3 trigger for pakreqBot
# Author::      KayMW
# Copyright::   Copyright (c) 2018 KayMW <RedL0tus@users.noreply.github.com>
# License::     Do What The Fuck You Want To Public License, Version 2.

require 'sqlite3'
require 'rbconfig'

module DB
  # SQLite3 trigger
  # Params:
  # +filename+:: filename of the SQLite3 database
  def initialize(filename)
    @filename = filename
    @db = SQLite3::Database.new(@filename)
  end

  def init_db()
    # Initialize database
    begin
      @db.execute(
        'CREATE TABLE IF NOT EXISTS requests('
        'id             INT     NOT NULL    PRIMARY KEY,'
        'category       INT     NOT NULL,'
        'status         INT     NOT NULL,'
        'pkgname        TEXT    NOT NULL,'
        'desc           TEXT,'
        'maintainer_id  INT,'
        'requester_id   INT,'
        'eta            TEXT'
        ');'
      )
      @db.execute(
        'CREATE TABLE IF NOT EXISTS users('
        'id           INT   NOT NULL  PRIMARY KEY,'
        'admin        INT,'
        'subscribe    INT,'
        'tg_username  TEXT,'
        'tg_id        INT,'
        'irc          TEXT,'
        'email        TEXT,'
      )
      return true
    rescue
      return false
  end

  def get_last_id()
    # Get the lagest request ID
    begin
      id = @db.execute(
        'SELECT id FROM requests WHERE id = (SELECT MAX(id) FROM requests)'
      )
      return id
    rescue
      return 0
    end
  end
  
  def get_pakreq()
    # Get a list of all the pakreq
    begin
      list = @db.execute(
        'SELECT * FROM requests WHERE category = 1 AND status = 1;'
      )
      return list, true
    rescue
      return nil, false
    end
  end

  def get_updreq()
    # Get a list of all the updreq
    begin
      list = @db.execute(
        'SELECT * FROM requests WHERE category = 2 AND status = 1;'
      )
      return list, true
    rescue
      return nil, false
    end
  end

  def get_optreq()
    # Get a list of all the optreq
    begin
      list = @db.execute(
        'SELECT * FROM requests WHERE category = 3 AND status = 1;'
      )
      return list, true
    rescue
      return nil, false
    end
  end

  def get_req()
    # Get a list of all the requests
    begin
      list = @db.execute(
        'SELECT * FROM requests WHERE status = 1;'
      )
      return list, true
    rescue
      return nil, false
    end
  end

  def add_pakreq(*args)
    # Add a pakreq
    begin
      temp = { }
      args.map do |arg|
        temp = res.merge(arg)
      end
      id = get_last_id() + 1
      @db.execute(
        'INSERT INTO requests (id,category,status,pkgname,desc,requester_id)
          VALUES (?,?,?,?,?,?)',[id, 1, 1, temp[:pkgname], temp[:desc], temp[:requester_id]]
      )
      return id, true
    rescue
      return nil, false
    end
  end

  def add_updreq(*args)
    # Add a updreq
    begin
      temp = { }
      args.map do |arg|
        temp = res.merge(arg)
      end
      id = get_last_id() + 1
      @db.execute(
        'INSERT INTO requests (id,category,status,pkgname,desc,requester_id)
          VALUES (?,?,?,?,?,?)',[id, 2, 1, temp[:pkgname], temp[:desc], temp[:requester_id]]
      )
      return id, true
    rescue
      return nil, false
    end
  end

  def add_optreq(*args)
    # Add a optreq
    begin
      temp = { }
      args.map do |arg|
        temp = res.merge(arg)
      end
      id = get_last_id() + 1
      @db.execute(
        'INSERT INTO requests (id,category,status,pkgname,desc,requester_id)
          VALUES (?,?,?,?,?,?)',[id, 3, 1, temp[:pkgname], temp[:desc], temp[:requester_id]]
      )
      return id, true
    rescue
      return nil, false
    end
  end
end
