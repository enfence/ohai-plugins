# Encoding: utf-8
# Author:: Andrey Klyachkin <andrey.klyachkin@enfence.com>
# Based on original Chef Plugin written by:
# Author:: Julian C. Dunn (<jdunn@chef.io>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright (C) 2016 eNFence GmbH
# License: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Services) do
  provides 'services'

  collect_data(:aix) do
    services Mash.new
    so = shell_out('lssrc -a | grep active$')
    so.stdout.lines do |line|
      line = line.split(' ')
      group = if line.length == 4
                line[1]
              else
                ''
              end
      pid = if line.length == 4
              line[2]
            else
              line[1]
            end
      state = if line.length == 4
                line[3]
              else
                line[2]
              end
      services[line[0]] = {
        "output" => line[1..-1].join(' '),
        "group" => group,
        "pid" => pid,
        "state" => state
      }
    end
  end
end
