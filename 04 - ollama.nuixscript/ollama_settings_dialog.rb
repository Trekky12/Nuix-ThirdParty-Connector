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
java_import javax.swing.JTextArea

class OllamaSettingsDialog < SettingsDialog
  def initialize(parent, file_destination)
    super parent, file_destination
    setTitle "Ollama API Settings"

    label_model = JLabel.new("Model:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_model, constraints)

    @field_model = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 5
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_model, constraints)

    @fields["model"] = @field_model

    label_prompt = JLabel.new("Prompt:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 6
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_prompt, constraints)

    @field_prompt = JTextArea.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 6
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_prompt.setRows(5)
    @field_prompt.text = "{document}"
    @content_panel.add(@field_prompt, constraints)

    @fields["prompt"] = @field_prompt

    load_properties()

    pack
  end
end
