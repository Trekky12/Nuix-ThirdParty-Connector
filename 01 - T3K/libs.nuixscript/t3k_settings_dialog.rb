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

require "java"

require_relative "../../libs.nuixscript/settings_dialog.rb"

class T3KSettingsDialog < SettingsDialog
  def initialize(parent, file_destination)
    super parent, file_destination
    setTitle "T3K API Settings"

    label_srv_folder = JLabel.new("Mounted Folder on T3K-Server:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_srv_folder, constraints)

    @field_srv_folder = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_srv_folder, constraints)

    label_nalvis_keepalive = JLabel.new("NaLVis Session Keep Alive:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 6
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_nalvis_keepalive, constraints)

    @field_nalvis_keepalive = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 6
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_nalvis_keepalive.text = "60"
    @content_panel.add(@field_nalvis_keepalive, constraints)

    @fields["srv_folder"] = @field_srv_folder
    @fields["nalvis_keepalive"] = @field_nalvis_keepalive

    # Reload properties
    load_properties()

    pack
  end
end
