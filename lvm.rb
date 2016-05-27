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

Ohai.plugin(:LVM) do
  provides "lvols"
  provides "pvols"
  provides "volgrps"

  collect_data(:aix) do
    lvols Mash.new
    pvols Mash.new
    volgrps Mash.new
    so = shell_out("lsvg -L | lsvg -Lli | grep -v '^LV NAME'")
    out = so.stdout.lines

    # Output format is
    # LV_NAME TYPE LPs PPs PVs LV_STATE MOUNT_POINT
    vgname = ''
    out.each do |line|
      lvname, lvtype, lps, pps, pvs, lvstate, mntpoint = line.split(" ", 7)
      if lvname.end_with?(':')
        # if lvname ends with : it is a vgname
        vgname = lvname[0..-2]
      else
        lvid = ''
        lvcopies = ''
        lvlabel = ''
        lvupper = ''
        lvstrict = ''
        so = shell_out("lsattr -El #{lvname} -a lvserial_id -a copies -a label -a upperbound -a strictness -F attribute:value")
        so.stdout.lines.each do |attrout|
          a, v = attrout.split(':')
          case a
          when "lvserial_id"
            lvid = v[0..-2]
          when "copies"
            lvcopies = v[0..-2]
          when "label"
            lvlabel = v[0..-2]
          when "upperbound"
            lvupper = v[0..-2]
          when "strictness"
            lvstrict = v[0..-2]
          end
        end
        lvols[lvname] = {
          "name" => lvname,
          "vg" => vgname,
          "type" => lvtype,
          "id" => lvid,
          "copies" => lvcopies,
          "label" => lvlabel,
          "maxpvs" => lvupper,
          "strictness" => lvstrict,
          "lps" => lps,
          "pps" => pps,
          "pvs" => pvs,
          "mount" => mntpoint[0..-2]
        }
      end
    end

    so = shell_out("lsvg -L | lsvg -Lpi | grep -v '^PV_NAME'")
    out = so.stdout.lines

    # Output format is
    # PV_NAME PV_STATE TOTAL_PPS FREE_PPS FREE_DISTRIBUTION
    out.each do |line|
      pvid = ''
      ppsize = ''
      lvnum = ''
      stale = ''
      max_transfer = ''
      reserve_policy = ''
      queue_depth = ''
      pvname, pvstate, totalpps, freepps, freedist = line.split(" ", 5)
      if pvname.end_with?(':')
        vgname = pvname[0..-2]
      else
        plvols Mash.new
        so = shell_out("lspv -Ll #{pvname} | grep -Ev '^(LV NAME|#{pvname})'")
        so.stdout.lines.each do |lvout|
          lvname, lps, pps, dist, mntpoint = lvout.split(" ", 5)
          plvols[lvname] = {
            "lps" => lps,
            "pps" => pps,
            "distribution" => dist,
            "mount" => mntpoint[0..-2]
          }
        end
        so = shell_out("lspv -L #{pvname}")
        so.stdout.lines.each do |pvout|
          if pvout.start_with?("PV IDENTIFIER")
            pvid = pvout.split(" ")[2]
          end
          if pvout.start_with?("STALE PARTITIONS")
            stale = pvout.split(" ")[2]
          end
          if pvout.start_with?("PP SIZE")
            ppsize = pvout.split(" ")[2]
            lvnum = pvout.split(" ")[6]
          end
        end
        so = shell_out("lsattr -El #{pvname} -a max_transfer -a reserve_policy -a queue_depth -F attribute:value")
        so.stdout.lines.each do |attrout|
          a, v = attrout.split(':')
          case a
          when "max_transfer"
            max_transfer = v[0..-2]
          when "reserve_policy"
            reserve_policy = v[0..-2]
          when "queue_depth"
            queue_depth = v[0..-2]
          end
        end
        pvols[pvname] = {
          "name" => pvname,
          "pvid" => pvid,
          "vg" => vgname,
          "ppsize" => ppsize,
          "lvnum" => lvnum,
          "stalepps" => stale,
          "state" => pvstate,
          "pps" => totalpps,
          "free" => freepps,
          "max_transfer" => max_transfer,
          "reserve_policy" => reserve_policy,
          "queue_depth" => queue_depth,
          "distribution" => freedist[0..-2],
          "lvols" => plvols
        }
      end
    end

    so = shell_out("lsvg -L")
    out = so.stdout.lines
    out.each do |vg|
      vgid = ''
      vgstate = ''
      ppsize = ''
      totalpps = ''
      freepps = ''
      maxlvs = ''
      lvnum = ''
      usedpps = ''
      totalpvs = ''
      stalepps = ''
      maxppsvg = ''
      maxppspv = ''
      maxpvs = ''
      vg = vg[0..-2]
      so = shell_out("lsvg -L #{vg}")
      so.stdout.lines.each do |vgout|
        if vgout.start_with?("VOLUME GROUP")
          vgid = vgout.split(" ")[5]
        end
        if vgout.start_with?("VG STATE")
          vgstate = vgout.split(" ")[2]
          ppsize = vgout.split(" ")[5]
        end
        if vgout.start_with?("VG PERMISSION")
          totalpps = vgout.split(" ")[5]
        end
        if vgout.start_with?("MAX LVs")
          maxlvs = vgout.split(" ")[2]
          freepps = vgout.split(" ")[5]
        end
        if vgout.start_with?("LVs")
          lvnum = vgout.split(" ")[1]
          usedpps = vgout.split(" ")[4]
        end
        if vgout.start_with?("TOTAL PVs")
          totalpvs = vgout.split(" ")[2]
        end
        if vgout.start_with?("STALE PVs")
          stalepps = vgout.split(" ")[5]
        end
        if vgout.start_with?("MAX PPs per VG")
          maxppsvg = vgout.split(" ")[4]
          maxpvs = vgout.split(" ")[7]
        end
        if vgout.start_with?("MAX PPs per PV")
          maxppspv = vgout.split(" ")[4]
          maxpvs = vgout.split(" ")[7]
        end
      end
      volgrps[vg] = {
        "id" => vgid,
        "state" => vgstate,
        "pp_size" => ppsize,
        "pp_total" => totalpps,
        "pp_free" => freepps,
        "pp_used" => usedpps,
        "pp_stale" => stalepps,
        "pp_vg_max" => maxppsvg,
        "pp_pv_max" => maxppspv,
        "lv_max" => maxlvs,
        "lv_count" => lvnum,
        "pv_max" => maxpvs,
        "pv_count" => totalpvs,
        "lvols" => [],
        "pvols" => []
      }
    end
    lvols.each do |k, v|
      volgrps[v["vg"]]["lvols"] << lvols[k]
    end
    pvols.each do |k, v|
      volgrps[v["vg"]]["pvols"] << pvols[k]
    end
  end
end
