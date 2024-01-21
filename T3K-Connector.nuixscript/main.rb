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

require 'java'

java_import javax.swing.JFrame
java_import javax.swing.JPanel
java_import javax.swing.JButton
java_import javax.swing.JOptionPane
java_import javax.swing.border.EmptyBorder

require_relative "t3k_analysis.rb"
require_relative "settings_dialog.rb"
require_relative "nalvis_frame.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, "data.properties")

# Configuration
REST_API_TIMEOUT = 1800 # 30 min
POLLING_INTERVAL = nil
MAX_LINES = 1000
PHASES_ANALYSIS = 3
PHASES_NALVIS = 3
CUSTOM_METADATA_FIELD_NAME = "T3K Detections"
NALVIS_SESSION_KEEP_ALIVE_INTERVAL = 60 # 1 min

class T3KMainFrame < JFrame
  def initialize(window, current_case, current_selected_items, utilities)
    super "T3K Analysis"
    setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE

    panel = JPanel.new(java.awt.GridBagLayout.new)
    panel.setBorder(EmptyBorder.new(10, 10, 10, 10))

    constraints = java.awt.GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 1
    constraints.anchor = java.awt.GridBagConstraints::NORTHWEST
    constraints.insets = java.awt.Insets.new(10, 10, 10, 10)
    constraints.weightx = 1.0
    btn_analysis = JButton.new("Analysis and Classification")
    if current_selected_items.size > 0
      btn_analysis.setEnabled(true)
    else
      btn_analysis.setEnabled(false)
    end
    panel.add(btn_analysis, constraints)

    btn_analysis.addActionListener do |event|
      begin
        analysis_frame = T3KAnalysisFrame.new window, current_case, current_selected_items, utilities, @properties
        analysis_frame.setVisible true
        dispose
      rescue StandardError => e
        JOptionPane.showMessageDialog(self, "An error occurred: #{e.message}")
      end
    end

    constraints = java.awt.GridBagConstraints.new
    constraints.gridx = 0
    constraints.gridy = 2
    constraints.anchor = java.awt.GridBagConstraints::NORTHWEST
    constraints.insets = java.awt.Insets.new(10, 10, 10, 10)
    constraints.weightx = 1.0
    constraints.weighty = 1.0
    btn_nalvis = JButton.new("NaLViS Search")
    #btn_nalvis.setEnabled(false)
    panel.add(btn_nalvis, constraints)

    btn_nalvis.addActionListener do |event|
      begin
        nalvis_frame = NalvisFrame.new window, current_case, current_selected_items, utilities, @properties
        nalvis_frame.setVisible true
        dispose
      rescue StandardError => e
        JOptionPane.showMessageDialog(self, "An error occurred: #{e.message}")
      end
    end

    @dialog = SettingsDialog.new SETTINGS_FILE
    @dialog.get_save_button.addActionListener do |event|
      begin
        @dialog.write_properties()
        puts "Data saved to #{SETTINGS_FILE}"
      rescue Exception => e
        puts "Error saving data: #{e.message}"
        JOptionPane.showMessageDialog(self, "Error saving data: #{e.message}")
      end
      JOptionPane.showMessageDialog(self, "Data saved, please re-open the script.")
      @dialog.dispose
      dispose
    end

    menu_bar = JMenuBar.new
    settings_menu = JMenu.new("Settings")
    settings_item = JMenuItem.new("Settings")
    settings_item.addActionListener do |event|
      @dialog.setVisible(true)
    end
    settings_menu.add(settings_item)
    menu_bar.add(settings_menu)
    setJMenuBar(menu_bar)

    setContentPane(panel)
    setMinimumSize(java.awt.Dimension.new(200, 150))
    pack

    # Check if settings exists
    if !File.exists?(SETTINGS_FILE)
      @dialog.setVisible(true)
    end

    @properties = @dialog.read_properties
  end
end

begin
    main = T3KMainFrame.new window, current_case, current_selected_items, utilities
    main.setVisible true
  rescue StandardError => e
    JOptionPane.showMessageDialog(self, "An error occurred: #{e.message}")
  end
  
  return 1