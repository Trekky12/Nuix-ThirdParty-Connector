# encoding: UTF-8

# This file is part of Nuix-ThirdParty-Connector (https://github.com/trekky12/nuix-thirdparty-connector).
# Copyright (c) 2024 Trekky12
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "nalvis_frame.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, "..", "data.properties")

begin
  if !File.exists? SETTINGS_FILE
    dialog = T3KSettingsDialog.new nil, SETTINGS_FILE
    dialog.setVisible true
  end
  nalvis_frame = NalvisFrame.new window, current_case, current_selected_items, utilities, SETTINGS_FILE
  nalvis_frame.setVisible true
rescue StandardError => e
  JOptionPane.showMessageDialog(nil, "An error occurred: #{e.message}")
end

return 0