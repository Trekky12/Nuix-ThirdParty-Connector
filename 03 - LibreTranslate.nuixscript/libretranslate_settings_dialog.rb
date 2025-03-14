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

require_relative "../libs.nuixscript/settings_dialog.rb"

class LibreTranslateSettingsDialog < SettingsDialog
  def initialize(parent, file_destination)
    super parent, file_destination
    setTitle "LibreTranslate API Settings"

    label_target = JLabel.new("Target Language:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_target, constraints)

    @field_target = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_target, constraints)

    @fields["target"] = @field_target

    # Reload properties
    load_properties()

    pack
  end
end
