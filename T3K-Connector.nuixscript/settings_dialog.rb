# This file is part of Nuix-T3K-Connector (https://github.com/trekky12/nuix-t3k-connector).
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

class SettingsDialog < JDialog
  def initialize(file_destination)
    super(nil, "Settings", true)
    set_size(400, 300)
    set_location_relative_to(nil) # Center on screen
    setMinimumSize(java.awt.Dimension.new(400, 300))

    @file_destination = file_destination

    content_panel = JPanel.new(GridBagLayout.new)
    add(content_panel)

    label_api_host = JLabel.new("API-Host:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 0
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    content_panel.add(label_api_host, constraints)

    @field_api_host = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 0
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    content_panel.add(@field_api_host, constraints)

    label_port = JLabel.new("API-Port:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 1
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    content_panel.add(label_port, constraints)

    @field_api_port = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 1
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_api_port.text = "5000"
    content_panel.add(@field_api_port, constraints)

    label_export_folder = JLabel.new("Export Folder (Network-Path):")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 2
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    content_panel.add(label_export_folder, constraints)

    @field_export_folder = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 2
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    content_panel.add(@field_export_folder, constraints)

    label_srv_folder = JLabel.new("Mounted Folder on T3K-Server:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 3
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    content_panel.add(label_srv_folder, constraints)

    @field_srv_folder = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 3
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    content_panel.add(@field_srv_folder, constraints)

    label_batch_size = JLabel.new("Batch Size:")
    constraints = GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 4
    constraints.fill = GridBagConstraints::VERTICAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 10, 6, 6)
    content_panel.add(label_batch_size, constraints)

    @field_batch_size = JTextField.new
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 4
    constraints.fill = GridBagConstraints::HORIZONTAL
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 6, 6, 10)
    constraints.weightx = 1.0
    @field_batch_size.text = "10"
    content_panel.add(@field_batch_size, constraints)

    @save_button = JButton.new("Save")
    constraints = GridBagConstraints.new
    constraints.gridx = 1
    constraints.gridy = 5
    constraints.anchor = GridBagConstraints::NORTHWEST
    constraints.insets = Insets.new(10, 4, 6, 6)
    constraints.weighty = 1.0
    content_panel.add(@save_button, constraints)

    # Read values from file and populate text fields
    begin
      if File.exist?(@file_destination)
        data = read_properties()
        @field_api_host.set_text(data["api_host"].to_s)
        @field_api_port.set_text(data["api_port"].to_s)
        @field_export_folder.set_text(data["export_folder"].to_s)
        @field_srv_folder.set_text(data["srv_folder"].to_s)
        @field_batch_size.set_text(data["batch_size"].to_s)
      end
    rescue Exception => e
      puts "Error reading data: #{e.message}"
    end

  end

  def get_save_button
    return @save_button
  end

  def read_properties()
    properties = {}
    File.open(@file_destination, "r") do |file|
      file.each_line do |line|
        key, value = line.strip.split("=")
        properties[key] = value
      end
    end
    properties
  end

  def write_properties()
    data = {
      "api_host" => @field_api_host.get_text,
      "api_port" => @field_api_port.get_text,
      "export_folder" => @field_export_folder.get_text,
      "srv_folder" => @field_srv_folder.get_text,
      "batch_size" => @field_batch_size.get_text,
    }
    File.open(@file_destination, "w") do |file|
      data.each do |key, value|
        file.puts("#{key}=#{value}")
      end
    end
  end
end
