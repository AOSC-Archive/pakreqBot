#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

require 'rbconfig'
require_relative '../libs/database.rb'

puts "================================"
puts "Start testing module Database..."
puts "================================"

# Initialize test database
status = Database::initialize_database
if status == true
  puts "[ \033[32mOK\033[0m ] Test database initialized."
else
  puts "[FAIL] Test database initialization failed."
  exit
end

# Open database
db = Database.db_open
if db[1] == true
  puts "[ \033[32mOK\033[0m ] Test database successfully opened."
else
  puts "[FAIL] Test database cannot be opened."
  exit
end

# Add a pakreq
status = Database.pkg_add(db,"req","testPkg","testDesc",1,"testPackager","2333333333","testRequester","666666666","2017-07-06",nil,nil)
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_add\"(req) works correctly."
else
  puts "[FAIL] Function \"pkg_add\"(req) failed."
  exit
end

# Add a done pakreq
status = Database.pkg_add(db,"done","testDonePkg","testDoneDesc",1,"testDonePackager","23333333","testDoneRequester","66666666","2017-07-06",nil,nil)
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_add\"(done) works correctly."
else
  puts "[FAIL] Function \"pkg_add\"(done) failed."
  exit
end

# Add a rejected pakreq
status = Database.pkg_add(db,"rejected","testRejPkg","testRejDesc",1,"testRejPackager","2333333","testRejRequester","6666666","2017-07-06",nil,"testRejReason")
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_add\"(rejected) works correctly."
else
  puts "[FAIL] Function \"pkg_add\"(rejected) failed."
  exit
end

# List pakreq
status = Database.pkg_list(db,"req")
if status[1] == false
  puts "[FAIL] Function \"pkg_list\"(req) failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testPkg") and (arr[1] == "testDesc") and (arr[3] == "testPackager") and (arr[4] == "2333333333") and (arr[5] == "testRequester") and (arr[6] == "666666666")
    puts "[ \033[32mOK\033[0m ] Function \"pkg_list\"(req) works correctly."
  else
    puts "[FAIL] Function \"pkg_list\"(req) failed."
    exit
  end
end

# List done pakreq
status = Database.pkg_list(db,"done")
if status[1] == false
  puts "[FAIL] Function \"pkg_list\"(done) failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testDonePkg") and (arr[1] == "testDoneDesc") and (arr[3] == "testDonePackager") and (arr[4] == "23333333") and (arr[5] == "testDoneRequester") and (arr[6] == "66666666")
    puts "[ \033[32mOK\033[0m ] Function \"pkg_list\"(done) works correctly."
  else
    puts "[FAIL] Function \"pkg_list\"(done) failed."
    exit
  end
end

# List rejected pakreq
status = Database.pkg_list(db,"rejected")
if status[1] == false
  puts "[FAIL] Function \"pkg_list\"(rejected) failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testRejPkg") and (arr[1] == "testRejDesc") and (arr[3] == "testRejPackager") and (arr[4] == "2333333") and (arr[5] == "testRejRequester") and (arr[6] == "6666666")
    puts "[ \033[32mOK\033[0m ] Function \"pkg_list\"(rejected) works correctly."
  else
    puts "[FAIL] Function \"pkg_list\"(rejected) failed."
    exit
  end
end

# Claim pakreq
status = Database.pkg_claim(db,"testPkg","testReqPackager","233333333")
if status == false
  puts "[FAIL] Function \"pkg_claim\" failed."
  exit
end
status = Database.pkg_list(db,"req")
if status[1] == false
  puts "[FAIL] Function \"pkg_claim\" failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testPkg") and (arr[1] == "testDesc") and (arr[3] == "testReqPackager") and (arr[4] == "233333333") and (arr[5] == "testRequester") and (arr[6] == "666666666")
    puts "[ \033[32mOK\033[0m ] Function \"pkg_claim\" works correctly."
  else
    puts "[FAIL] Function \"pkg_claim\" failed."
    exit
  end
end

# Mark done
status = Database.pkg_done(db,"testPkg","233333333")
if status == false
  puts "[FAIL] Function \"pkg_done\" failed."
  exit
end
status = Database.pkg_list(db,"done")
if status[1] == false
  puts "[FAIL] Function \"pkg_done\" failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testPkg") and (arr[1] == "testDesc") and (arr[3] == "testReqPackager") and (arr[4] == "233333333") and (arr[5] == "testRequester") and (arr[6] == "666666666")
    status = true
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_done\" works correctly."
else
  puts "[FAIL] Function \"pkg_done\" failed."
  exit
end

# Reject pakreq
Database.pkg_add(db,"req","testPkg","testDesc",1,"testPackager","233333333","testRequester","666666666","2017-07-06",nil,nil)
status = Database.pkg_reject(db,"testPkg","testPackager","233333333","testReason")
if status == false
  puts "[FAIL] Function \"pkg_reject\" failed."
  exit
end
status = Database.pkg_list(db,"rejected")
if status[1] == false
  puts "[FAIL] Function \"pkg_reject\" failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testPkg") and (arr[1] == "testDesc") and (arr[3] == "testPackager") and (arr[4] == "233333333") and (arr[5] == "testRequester") and (arr[6] == "666666666") and (arr[8] == "testReason")
    status = true
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_reject\" works correctly."
else
  puts "[FAIL] Function \"pkg_reject\" failed."
  exit
end

# Delete req
status = Database.pkg_del(db,"rejected","testPkg")
if status == false
  puts "[FAIL] Function \"pkg_del\" failed."
  exit
end
status = Database.pkg_list(db,"rejected")
if status[1] == false
  puts "[FAIL] Function \"pkg_del\" failed."
  exit
end
pkglist = status[0]
pkglist.map do |arr|
  if (arr[0] == "testPkg")
    status = false
  else
    status = true
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"pkg_del\" works correctly."
else
  puts "[FAIL] Function \"pkg_del\" failed."
  exit
end

# List users
status = Database.user_list(db)
if status[1] == true
  puts "[ \033[32mOK\033[0m ] Function \"user_list\" works correctly."
else
  puts "[FAIL] Function \"user_list\" failed."
  exit
end

# Register user
status = Database.user_reg(db,"233333333","testUser")
if status == false
  puts "[FAIL] Function \"user_reg\" failed. 1"
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if arr[0] == "233333333"
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_reg\" works correctly."
else
  puts "[FAIL] Function \"user_reg\" failed. 2"
  exit
end

# Set admin
status = Database.user_set(db,"admin","233333333",true)
if status == false
  puts "[FAIL] Function \"user_set\"(set admin) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[2] == 1)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(set admin) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(set admin) failed."
  exit
end

# Cancle admin
status = Database.user_set(db,"admin","233333333",false)
if status == false
  puts "[FAIL] Function \"user_set\"(cancle admin) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[2] == 0)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(cancle admin) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(cancle admin) failed."
  exit
end

# Activate session
status = Database.user_set(db,"session","233333333",true)
if status == false
  puts "[FAIL] Function \"user_set\"(activate session) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[3] == 1)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(activate session) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(activate session) failed."
  exit
end

# Deactivate session
status = Database.user_set(db,"session","233333333",false)
if status == false
  puts "[FAIL] Function \"user_set\"(deactivate session) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[3] == 0)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(deactivate session) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(deactivate session) failed."
  exit
end

# Subscribe
status = Database.user_set(db,"subscribe","233333333",true)
if status == false
  puts "[FAIL] Function \"user_set\"(subscribe) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[4] == 1)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(subscribe) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(subscribe) failed."
  exit
end

# Subscribe
status = Database.user_set(db,"subscribe","233333333",false)
if status == false
  puts "[FAIL] Function \"user_set\"(unsubscribe) failed."
  exit
end
status = Database.user_list(db)
status[0].map do |arr|
  if (arr[0] == "233333333") and (arr[4] == 0)
    status = true
  else
    status = false
  end
end
if status == true
  puts "[ \033[32mOK\033[0m ] Function \"user_set\"(unsubscribe) works correctly."
else
  puts "[FAIL] Function \"user_reg\"(unsubscribe) failed."
  exit
end

# Cleanup
if RbConfig::CONFIG['target_os'] == 'mswin32'
  slash = "\\"
else
  slash = "/"
end
File.delete("data#{slash}database.db")
Dir.delete("data")
puts "================================"
puts "All check."
puts "================================"
