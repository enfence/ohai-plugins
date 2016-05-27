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

Ohai.plugin(:PowerVM) do
  provides "virtualization"

  collect_data(:aix) do
    virtualization Mash.new
    virtualization[:system] = "powervm"
    so = shell_out("lparstat -i")
    so.stdout.lines do |line|
      v = line.split(':')
      if v[0].start_with?("Partition Name")
        virtualization[:lpar_name] = v[1].delete(" ")[0..-2]
      elsif v[0].start_with?("Partition Number")
        virtualization[:lpar_no]  = v[1].delete(" ")[0..-2]
      else
        sym = v[0].strip.downcase.gsub(/ /, '_')
        virtualization[sym.to_sym] = v[1].delete(" ")[0..-2]
      end
    end
    so = shell_out("lsattr -El sys0 -a fwversion -a systemid -a modelname -a os_uuid -F attribute:value")
    so.stdout.lines do |line|
      v = line.split(':')
      virtualization[v[0].to_sym] = v[1][0..-2].gsub("IBM,", "")
    end
  end
end
