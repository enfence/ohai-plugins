# Encoding: utf-8
# Author:: Andrey Klyachkin <andrey.klyachkin@enfence.com>
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

Ohai.plugin(:AIXUsers) do
  provides "users"

  collect_data(:aix) do
    users Mash.new

    so = shell_out("lsuser -C ALL")
    names = []
    so.stdout.lines.each do |line|
      line.chomp!
      if line.start_with?('#')
        names = line.sub(/^#/, '').split(':')
      else
        values = line.split(':')
        users[values[0]] = Hash.new
        values[1..-1].each_with_index do |v, k|
          users[values[0]][names[k+1].to_sym] = v
        end
      end
    end
  end
end
