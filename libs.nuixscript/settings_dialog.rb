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
java_import javax.swing.JDialog
java_import javax.swing.JPanel
java_import javax.swing.JLabel
java_import javax.swing.JTextField
java_import javax.swing.JButton
java_import java.awt.GridBagLayout
java_import java.awt.GridBagConstraints
java_import java.awt.Insets
java_import java.awt.event.ActionListener
java_import java.io.FileReader
java_import java.io.FileWriter
java_import java.io.BufferedReader
java_import java.io.BufferedWriter

require_relative "helper.rb"

# Configuration
MAX_LOG_LINES = 1000

class SettingsDialog < JDialog
  def initialize(parent, file_destination)
    super(nil, "Settings", true)
    set_size(400, 300)
    set_location_relative_to(nil) # Center on screen
    setMinimumSize(java.awt.Dimension.new(400, 300))

    @parent = parent
    @file_destination = file_destination

    @content_panel = JPanel.new(GridBagLayout.new)
    add(@content_panel)

    label_api_host = JLabel.new("API-Host:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 0
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_api_host, constraints)

    @field_api_host = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 0
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_api_host, constraints)

    label_port = JLabel.new("API-Port:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 1
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_port, constraints)

    @field_api_port = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 1
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_api_port.text = "5000"
    @content_panel.add(@field_api_port, constraints)

    label_metadata_name = JLabel.new("Metadata Name:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 2
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_metadata_name, constraints)

    @field_metadata_name = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 2
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_metadata_name, constraints)

    label_export_folder = JLabel.new("Export Folder:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 3
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_export_folder, constraints)

    @field_export_folder = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 3
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @content_panel.add(@field_export_folder, constraints)

    label_batch_size = JLabel.new("Batch Size:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 4
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    @content_panel.add(label_batch_size, constraints)

    @field_batch_size = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 4
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_batch_size.text = "10"
    @content_panel.add(@field_batch_size, constraints)

    @save_button = JButton.new("Save")
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 100
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 4, 6, 6)
    constraints.weighty = 1.0
    @content_panel.add(@save_button, constraints)

    @fields = { "api_host" => @field_api_host,
                "api_port" => @field_api_port,
                "metadata_name" => @field_metadata_name,
                "export_folder" => @field_export_folder,
                "batch_size" => @field_batch_size }

    @save_button.addActionListener do |event|
      begin
        write_properties()
        puts "Data saved to #{SETTINGS_FILE}"
      rescue Exception => e
        puts "Error saving data: #{e.message}"
        JOptionPane.showMessageDialog(self, "Error saving data: #{e.message}")
      end
      dispose
      if @parent
        JOptionPane.showMessageDialog(self, "Data saved, please re-open the script.")
        @parent.dispose
      end
    end

    load_properties()
  end

  def get_save_button
    return @save_button
  end

  def load_properties
    # Read values from file and populate text fields
    begin
      if File.exist?(@file_destination)
        data = read_properties(@file_destination)
        @fields.each do |field_key, field_value|
          field_value.set_text(data[field_key].to_s)
        end
      end
    rescue Exception => e
      puts "Error reading data: #{e.message}"
    end
  end

  def write_properties()
    File.open(@file_destination, "w") do |file|
      @fields.each do |field_key, field_value|
        file.puts("#{field_key}=#{field_value.get_text}")
      end
    end
  end
end
