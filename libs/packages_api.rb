#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-

# Author: KayMW

# Copyright © 2017 KayMW <RedL0tus@users.noreply.github.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

module Packages_API
  def initialize(*targets)
    @targets = targets
  end

  def self.api_queue_pkg(pkgname)
    # TODO: Packages API
    return false
  end
end
