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

require "java"

require "json"
require "fileutils"
require "logger"
require "date"

java_import javax.swing.JFrame
java_import javax.swing.JPanel
java_import javax.swing.JLabel
java_import javax.swing.JButton
java_import javax.swing.JTextField
java_import javax.swing.border.EmptyBorder
java_import javax.swing.JProgressBar
java_import javax.swing.JScrollPane
java_import javax.swing.JTextPane
java_import java.awt.Font

java_import java.awt.event.WindowAdapter
java_import javax.swing.JOptionPane

java_import java.util.concurrent.LinkedBlockingDeque
java_import javax.swing.SwingUtilities

java_import javax.swing.JMenuBar
java_import javax.swing.JMenu
java_import javax.swing.JMenuItem

java_import javax.swing.JToggleButton
java_import javax.swing.JSlider
java_import javax.swing.ImageIcon
java_import java.awt.Image
java_import java.awt.image.BufferedImage

java_import java.awt.GridLayout
java_import java.awt.event.ComponentAdapter
java_import java.awt.event.ComponentEvent
java_import java.awt.event.ComponentListener
java_import java.awt.BorderLayout

java_import javax.swing.SwingWorker

require_relative "../../libs.nuixscript/helper.rb"
require_relative "../libs.nuixscript/t3k_settings_dialog.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, "..", "data.properties")

class NalvisFrame < JFrame
  def initialize(window, current_case, current_selected_items, utilities)
    super "T3K NaLViS Search"
    setDefaultCloseOperation JFrame::DO_NOTHING_ON_CLOSE

    @window = window
    @current_case = current_case

    @item_thumbnails = {}
    @resultData = []
    @resultDataSelected = {}

    properties = read_properties SETTINGS_FILE

    @api_host = properties["api_host"]
    @api_port = properties["api_port"]
    @batch_size = properties["batch_size"].to_i
    @custom_metadata_field_name = properties["metadata_name"]
    @nalvis_keep_alive_interval = properties["nalvis_keepalive"]

    case_location = @current_case.getLocation().getAbsolutePath
    log_file_path = File.join(case_location, "t3k-nalvis_#{Time.now.strftime("%Y%m%d")}.log")
    @logger = Logger.new(log_file_path)
    @logger::level = Logger::INFO

    @session_id = nil

    panel = JPanel.new(java.awt.GridBagLayout.new)
    panel.setBorder(EmptyBorder.new(10, 10, 10, 10))

    gbC_labelh = java.awt.GridBagConstraints.new
    gbC_labelh.gridx = 0
    gbC_labelh.gridy = 1
    gbC_labelh.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_labelh.anchor = java.awt.GridBagConstraints::WEST
    gbC_labelh.insets = java.awt.Insets.new(5, 10, 5, 10)
    labelh = JLabel.new("T3K NaLViS search")
    panel.add(labelh, gbC_labelh)

    gbc_btn_init = java.awt.GridBagConstraints.new
    gbc_btn_init.gridx = 0
    gbc_btn_init.gridy = 2
    gbc_btn_init.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_init.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_init = JButton.new("Initialize NaLViS Search")
    @btn_init.setEnabled(true)
    panel.add(@btn_init, gbc_btn_init)

    gbC_searchfield = java.awt.GridBagConstraints.new
    gbC_searchfield.gridx = 0
    gbC_searchfield.gridy = 3
    gbC_searchfield.fill = java.awt.GridBagConstraints::BOTH
    #gbC_searchfield.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_searchfield.anchor = java.awt.GridBagConstraints::WEST
    gbC_searchfield.insets = java.awt.Insets.new(5, 10, 5, 10)
    gbC_searchfield.weightx = 1.0
    @searchField = JTextField.new
    @searchField.setEnabled false

    panel.add(@searchField, gbC_searchfield)

    @searchField.addActionListener do |event|
      @btn_search.do_click
    end

    gbc_btn_search = java.awt.GridBagConstraints.new
    gbc_btn_search.gridx = 1
    gbc_btn_search.gridy = 3
    gbc_btn_search.fill = java.awt.GridBagConstraints::BOTH
    gbc_btn_search.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_search.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_search = JButton.new("Search..")
    @btn_search.setEnabled false
    panel.add(@btn_search, gbc_btn_search)

    gbC_label1 = java.awt.GridBagConstraints.new
    gbC_label1.gridx = 0
    gbC_label1.gridy = 5
    gbC_label1.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_label1.anchor = java.awt.GridBagConstraints::WEST
    gbC_label1.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label1 = JLabel.new(" ")
    panel.add(@label1, gbC_label1)

    gbC_label2 = java.awt.GridBagConstraints.new
    gbC_label2.gridx = 0
    gbC_label2.gridy = 6
    gbC_label2.anchor = java.awt.GridBagConstraints::WEST
    gbC_label2.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label2 = JLabel.new(" ")
    panel.add(@label2, gbC_label2)

    gridbagConstraints5 = java.awt.GridBagConstraints.new
    gridbagConstraints5.gridx = 0
    gridbagConstraints5.gridy = 7
    gridbagConstraints5.fill = java.awt.GridBagConstraints::HORIZONTAL
    gridbagConstraints5.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridbagConstraints5.weightx = 1.0
    gridbagConstraints5.insets = java.awt.Insets.new(5, 10, 5, 10)

    @progressBar = JProgressBar.new
    panel.add(@progressBar, gridbagConstraints5)

    gridBagConstraintsResultPane = GridBagConstraints.new
    gridBagConstraintsResultPane.gridx = 0
    gridBagConstraintsResultPane.gridy = 8
    gridBagConstraintsResultPane.fill = java.awt.GridBagConstraints::BOTH
    gridBagConstraintsResultPane.anchor = java.awt.GridBagConstraints::NORTHWEST
    gridBagConstraintsResultPane.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridBagConstraintsResultPane.weightx = 1.0
    gridBagConstraintsResultPane.weighty = 1.0
    gridBagConstraintsResultPane.insets = java.awt.Insets.new(0, 0, 0, 0)

    resultPane = JPanel.new(java.awt.GridBagLayout.new)
    panel.add(resultPane, gridBagConstraintsResultPane)

    gridBagConstraintsSliderPane = GridBagConstraints.new
    gridBagConstraintsSliderPane.gridx = 0
    gridBagConstraintsSliderPane.gridy = 0
    gridBagConstraintsSliderPane.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridBagConstraintsSliderPane.fill = java.awt.GridBagConstraints::BOTH
    gridBagConstraintsSliderPane.anchor = java.awt.GridBagConstraints::NORTHWEST
    gridBagConstraintsSliderPane.weightx = 1.0
    gridBagConstraintsSliderPane.insets = java.awt.Insets.new(0, 0, 0, 0)

    resultSliderPane = JPanel.new(java.awt.GridBagLayout.new)
    resultPane.add(resultSliderPane, gridBagConstraintsSliderPane)

    gridBagConstraintsSlider = GridBagConstraints.new
    gridBagConstraintsSlider.gridx = 0
    gridBagConstraintsSlider.gridy = 0
    gridBagConstraintsSlider.fill = java.awt.GridBagConstraints::BOTH
    gridBagConstraintsSlider.anchor = java.awt.GridBagConstraints::NORTHWEST
    gridBagConstraintsSlider.weightx = 1.0
    gridBagConstraintsSlider.insets = java.awt.Insets.new(5, 10, 5, 10)

    @resultSlider = JSlider.new
    @resultSlider.setEnabled false
    @resultSlider.setValueIsAdjusting true

    @resultSlider.addChangeListener do |event|
      SwingUtilities.invokeLater do
        @labelSlider.setText "#{(@resultSlider.value.to_f / 100).round(2)} - #{(@resultSlider.maximum.to_f) / 100.round(2)}%"
      end
    end

    resultSliderPane.add(@resultSlider, gridBagConstraintsSlider)

    gbC_labelSlider = java.awt.GridBagConstraints.new
    gbC_labelSlider.gridx = 1
    gbC_labelSlider.gridy = 0
    gbC_labelSlider.anchor = java.awt.GridBagConstraints::EAST
    gbC_labelSlider.insets = java.awt.Insets.new(5, 10, 5, 10)
    @labelSlider = JLabel.new(" ")
    resultSliderPane.add(@labelSlider, gbC_labelSlider)

    gbc_btn_filter = java.awt.GridBagConstraints.new
    gbc_btn_filter.gridx = 2
    gbc_btn_filter.gridy = 0
    gbc_btn_filter.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_filter.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_filter = JButton.new("Filter")
    @btn_filter.setEnabled false
    resultSliderPane.add(@btn_filter, gbc_btn_filter)

    @btn_filter.addActionListener do |event|
      Thread.new do
        begin
          log("Generate image list")

          threshold = @resultSlider.value / 100.0 / 100.0
          @resultDataSelected = @resultData.select { |data| data[1] >= threshold }.to_h
          log("Matches #{@resultDataSelected.length} items")

          if @resultDataSelected.length > 5000
            option = JOptionPane.showConfirmDialog(nil, "The expected result has #{@resultDataSelected.length} items. Do you want really want to render this (very slow)?", "Confirm", JOptionPane::YES_NO_OPTION)
          else
            option = JOptionPane::YES_OPTION
          end

          if option == JOptionPane::YES_OPTION
            worker = ImageAdderWorker.new
            worker.frame = self
            worker.execute
          end
        rescue StandardError => e
          log("An error occurred with rendering the images: #{e.message}")
        end
      end
    end

    gbc_btn_cancel = java.awt.GridBagConstraints.new
    gbc_btn_cancel.gridx = 0
    gbc_btn_cancel.gridy = 1
    gbc_btn_cancel.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_cancel.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_cancel = JButton.new("Cancel")
    @btn_cancel.setEnabled(false)
    resultPane.add(@btn_cancel, gbc_btn_cancel)

    @btn_cancel.addActionListener do |e|
      option = JOptionPane.showConfirmDialog(nil, "Do you want to stop the running process?", "Confirm", JOptionPane::YES_NO_OPTION)

      if option == JOptionPane::YES_OPTION
        stop_task
      end
    end

    gbC_scrollPaneR = java.awt.GridBagConstraints.new
    gbC_scrollPaneR.gridx = 0
    gbC_scrollPaneR.gridy = 2
    gbC_scrollPaneR.fill = java.awt.GridBagConstraints::BOTH
    gbC_scrollPaneR.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbC_scrollPaneR.weightx = 1.0
    gbC_scrollPaneR.weighty = 1.0
    gbC_scrollPaneR.insets = java.awt.Insets.new(5, 10, 5, 10)

    @resultThumbnailPane = JPanel.new(GridBagLayout.new)

    scrollPaneR = JScrollPane.new(JScrollPane::VERTICAL_SCROLLBAR_ALWAYS, JScrollPane::HORIZONTAL_SCROLLBAR_NEVER)
    scrollPaneR.setViewportView(@resultThumbnailPane)
    resultPane.add(scrollPaneR, gbC_scrollPaneR)

    gbc_btn_show_in_workbench = java.awt.GridBagConstraints.new
    gbc_btn_show_in_workbench.gridx = 0
    gbc_btn_show_in_workbench.gridy = 3
    gbc_btn_show_in_workbench.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_show_in_workbench.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_show_in_workbench = JButton.new("Show result in workbench")
    @btn_show_in_workbench.setEnabled false
    resultPane.add(@btn_show_in_workbench, gbc_btn_show_in_workbench)

    @btn_show_in_workbench.addActionListener do |event|
      Thread.new do
        begin
          @btn_show_in_workbench.setEnabled false
          @progressBar.setIndeterminate(true)

          guid_search = "guid:(#{@resultDataSelected.keys.join " OR "})"
          @window.openTab "workbench", { "search" => guid_search }
        rescue StandardError => e
          log("An error occurred with opening the workbench: #{e.message}")
        ensure
          @progressBar.setIndeterminate(false)
          @btn_show_in_workbench.setEnabled true
        end
      end
    end

    gridBagConstraintsLogPane = GridBagConstraints.new
    gridBagConstraintsLogPane.gridx = 0
    gridBagConstraintsLogPane.gridy = 9
    gridBagConstraintsLogPane.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridBagConstraintsLogPane.gridheight = java.awt.GridBagConstraints::REMAINDER
    gridBagConstraintsLogPane.fill = java.awt.GridBagConstraints::BOTH
    gridBagConstraintsLogPane.anchor = java.awt.GridBagConstraints::NORTHWEST
    gridBagConstraintsLogPane.weightx = 1.0
    gridBagConstraintsLogPane.insets = java.awt.Insets.new(0, 0, 0, 0)

    logPanel = JPanel.new(java.awt.GridBagLayout.new)
    panel.add(logPanel, gridBagConstraintsLogPane)

    gridBagConstraintsToggle = GridBagConstraints.new
    gridBagConstraintsToggle.gridx = 0
    gridBagConstraintsToggle.gridy = 0
    gridBagConstraintsToggle.anchor = java.awt.GridBagConstraints::NORTHWEST
    gridBagConstraintsToggle.insets = java.awt.Insets.new(0, 10, 0, 0)
    gridBagConstraintsToggle.weightx = 1.0

    log_toggle_btn = JToggleButton.new
    logPanel.add(log_toggle_btn, gridBagConstraintsToggle)

    log_toggle_btn.setText("Show Log")
    log_toggle_btn.addActionListener do |e|
      if @log_scroll_pane.isVisible()
        @log_scroll_pane.setVisible(false)
        log_toggle_btn.setText("Show Log")
      else
        @log_scroll_pane.setVisible(true)
        log_toggle_btn.setText("Hide Log")
      end
    end

    gbC_scrollPane = java.awt.GridBagConstraints.new
    gbC_scrollPane.gridx = 0
    gbC_scrollPane.gridy = 1
    gbC_scrollPane.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_scrollPane.gridheight = java.awt.GridBagConstraints::REMAINDER
    gbC_scrollPane.fill = java.awt.GridBagConstraints::BOTH
    gbC_scrollPane.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbC_scrollPane.weightx = 1.0
    gbC_scrollPane.insets = java.awt.Insets.new(5, 10, 5, 10)

    @log_text_pane = JTextPane.new
    @log_text_pane.editable = false

    font = Font.new(Font::MONOSPACED, Font::PLAIN, 12)
    @log_text_pane.font = font

    @log_scroll_pane = JScrollPane.new
    @log_scroll_pane.setViewportView(@log_text_pane)
    @log_scroll_pane.setVisible(false)
    @log_scroll_pane.setPreferredSize java.awt.Dimension.new(@log_scroll_pane.getPreferredSize.width, 200)
    @log_scroll_pane.setMinimumSize @log_scroll_pane.getPreferredSize
    logPanel.add(@log_scroll_pane, gbC_scrollPane)

    menu_bar = JMenuBar.new
    settings_menu = JMenu.new("Settings")
    settings_item = JMenuItem.new("Settings")
    settings_item.addActionListener do |event|
      dialog = T3KSettingsDialog.new self, SETTINGS_FILE
      dialog.setVisible true
    end
    settings_menu.add(settings_item)
    menu_bar.add(settings_menu)
    setJMenuBar(menu_bar)

    setContentPane(panel)
    setMinimumSize(java.awt.Dimension.new(800, 800))

    # Not that great with many images
    #add_component_listener(ResizeListener.new(self))
    pack

    @task_running = false
    @cancel_task = false

    add_window_listener(LogWindowAdapter.new)

    @btn_init.addActionListener do |e|
      t1 = Thread.new do
        begin
          @task_running = true
          @btn_init.setEnabled false
          @btn_cancel.setEnabled true
          items = init()
          if items == 0
            JOptionPane.showMessageDialog(self, "No items with NaLViS encodings found.")
          end
          if !@cancel_task && items > 0
            @btn_search.setEnabled true
            @searchField.setEnabled true
          else
            @btn_init.setEnabled true
          end
          @btn_cancel.setEnabled false
        rescue StandardError => e
          @logger.error("An error occurred: #{e.message}")
          JOptionPane.showMessageDialog(self, "An error occured: #{e.message}")
        ensure
          @task_running = false
          @cancel_task = false

          SwingUtilities.invokeLater do
            # Reset progressbar
            @progressBar.setIndeterminate(false)
            @progressBar.maximum = 0
            @progressBar.value = 0
            @label2.text = " "
          end
        end
      end
    end

    @btn_search.addActionListener do |e|
      t1 = Thread.new do
        begin
          @task_running = true
          @cancel_task = false
          @btn_init.setEnabled false
          @btn_search.setEnabled false
          @searchField.setEnabled false
          @btn_cancel.setEnabled true
          search()
          @btn_search.setEnabled true
          @searchField.setEnabled true
          @btn_cancel.setEnabled false
        rescue StandardError => e
          @logger.error("An error occurred: #{e.message}")
          JOptionPane.showMessageDialog(self, "An error occured: #{e.message}")
        ensure
          @task_running = false
          @cancel_task = false
        end
      end
    end

    @log_queue = LinkedBlockingDeque.new
    @logging_worker = LoggingWorker.new
    @logging_worker.frame = self
    @logging_worker.logger = @logger
    @logging_worker.execute

    @keep_alive_thread = Thread.new do
      loop do
        begin
          unless @session_id.nil?
            session_keep_alive_response = send_rest_request("post", "#{get_keep_alive_url()}", { "uids": ["#{@session_id}"] })
            if session_keep_alive_response.nil? || session_keep_alive_response.code.to_i != 200
              log "Session keep-alive failed, Status Code: #{session_keep_alive_response.code unless session_keep_alive_response.nil?}, Result: #{session_keep_alive_response.body unless session_keep_alive_response.nil?}"
            end

            begin
              response = JSON.parse(session_keep_alive_response.body)
            rescue JSON::ParserError => e
              log "Error parsing keep-alive response: #{e.message}"
            end
          end
        rescue StandardError => e
          @logger.error("An error occurred with the keep-alive: #{e.message}")
        end
        sleep(@nalvis_keep_alive_interval.to_i)
      end
    end
  end

  def get_create_session_url()
    "http://#{@api_host}:#{@api_port}/session"
  end

  def get_keep_alive_url()
    "http://#{@api_host}:#{@api_port}/keep-alive"
  end

  def get_search_url()
    "http://#{@api_host}:#{@api_port}/search"
  end

  def log(message)
    @logger.info("#{message}")
    prefix = DateTime.now.strftime "%Y-%d-%m %H:%M:%S"
    @log_queue.offer("[#{prefix}] #{message}")
  end

  def clear_log
    # Clear the deque and leave the last 1000 elements
    number_of_elements_to_leave = 100
    while @log_queue.size > number_of_elements_to_leave
      @log_queue.remove_first
    end
  end

  def increase_progress(rendering = false)
    SwingUtilities.invokeLater do
      @progressBar.value = @progressBar.value + 1
      prefix = "Retrieving"
      if rendering
        prefix = "Rendering"
      end
      if @progressBar.maximum > 0
        percentage = ((@progressBar.value.to_f / @progressBar.maximum) * 100)
      else
        percentage = 0.0
      end
      @label2.text = "#{prefix} Item #{@progressBar.value}/#{@progressBar.maximum} (#{percentage.round(0)}%)"
    end
  end

  def init()
    begin
      @label1.text = "Phase 1/3: Search possible result items"
      @progressBar.setIndeterminate(true)
      log("Search NaLViS encodings")

      nalvis_items = @current_case.searchUnsorted("custom-metadata:\"#{@custom_metadata_field_name}|nalvis\":*")
      log("Found #{nalvis_items.length} items")

      if nalvis_items.length == 0
        @progressBar.setIndeterminate(false)
        return 0
      end

      log("Create NaLViS session")

      @label1.text = "Phase 2/3: Create NaLViS Session"
      @label2.text = " "
      @progressBar.setIndeterminate(true)

      session_id = (Time.now.to_f * 1000).to_i
      payload = { "encodings" => nil }
      session_response = send_rest_request("post", "#{get_create_session_url()}/#{session_id}", payload)
      if session_response.nil? || session_response.code.to_i != 202
        log "Session creation failed, Status Code: #{session_response.code unless session_response.nil?}"
      else
        @session_id = session_id
      end

      begin
        response = JSON.parse(session_response.body)
      rescue JSON::ParserError => e
        log "Error parsing upload response: #{e.message}"
        response = {}
        @session_id = nil
      end

      log("Session-ID: #{@session_id}")
      log(response)

      # Add Encodings to session
      @progressBar.setIndeterminate(false)
      @progressBar.maximum = nalvis_items.length
      
      batch_number = 0
      total_batches = (nalvis_items.length / @batch_size.to_f).ceil

      nalvis_items.each_slice(@batch_size) do |batch|
        start = Time.now
        if @cancel_task
          log("Stopping batch!")
          break
        end

        log("=============================================================")
        batch_number += 1
        log "Processing batch #{batch_number} of #{total_batches}"

        # Collect encodings for items of this batch
        encodings = {}
        batch.each do |item|
          guid = item.getGuid()
          encoding = item.getCustomMetadata["#{@custom_metadata_field_name}|nalvis"]
          if encoding.length > 0
            @item_thumbnails[guid] = item.getThumbnail().getPage(0)
            
            #log("Add encoding for item #{guid}")
            
            begin
              parsed_encoding = JSON.parse(encoding)
            rescue JSON::ParserError => e
              log "Error parsing nalvis, probably no json: #{e.message}"
              parsed_encoding = encoding
            end
            encodings[guid] = parsed_encoding
          end
          increase_progress()
        end
        
        # Send encodings to session
        if encodings.size > 0
          log("Send encodings to session")
          
          payload = { "encodings" => encodings }
          #log("Payload: #{payload}")
          session_add_encoding_response = send_rest_request("put", "#{get_create_session_url()}/#{session_id}", payload)

          if session_add_encoding_response.nil? || session_add_encoding_response.code.to_i != 200
            log "Add encoding failed, Status Code: #{session_add_encoding_response.code unless session_add_encoding_response.nil?}"
          end

          begin
            response = JSON.parse(session_add_encoding_response.body)
          rescue JSON::ParserError => e
            log "Error parsing upload response: #{e.message}"
            response = {}
          end
          log(response)
        end
        
      end

      log("Get session status")
      processing_finished = false
      until processing_finished || @cancel_task
        session_status_response = send_rest_request("get", "#{get_create_session_url()}/#{@session_id}")
        if session_status_response.nil? || session_status_response.code.to_i != 200
          log "Session status failed, Status Code: #{session_status_response.code unless session_status_response.nil?}"
        end

        begin
          response = JSON.parse(session_status_response.body)
        rescue JSON::ParserError => e
          log "Error parsing session status response: #{e.message}"
          response = {}
        end

        if response["encodings_ready"]
          processing_finished = true
        end
      end

      if not @cancel_task
        @label1.text = "You are now able to search for a text in #{nalvis_items.length} items"
      else
        @label1.text = " "
      end
    rescue => e
      log "Error: #{e.message}"
    end

    return nalvis_items.length
  end

  def search()
    begin
      @label1.text = "Searching..."
      @label2.text = " "
      @progressBar.setIndeterminate(true)
      @resultSlider.setEnabled false
      @btn_filter.setEnabled false
      @btn_show_in_workbench.setEnabled false

      log("Search text #{@searchField.getText} in session #{@session_id}")

      log("Submitting text")

      search_submit_response = send_rest_request("post", "#{get_search_url()}/#{@session_id}/text", { "0": @searchField.getText })
      if search_submit_response.nil? || search_submit_response.code.to_i != 202
        log "Submitting text failed, Status Code: #{search_submit_response.code unless search_submit_response.nil?}"
        return
      end

      begin
        response = JSON.parse(search_submit_response.body)
      rescue JSON::ParserError => e
        log "Error parsing search submit response: #{e.message}"
        response = {}
      end

      log(response)

      log("Get text search status")
      processing_finished = false
      until processing_finished || @cancel_task
        search_text_response = send_rest_request("get", "#{get_search_url()}/#{@session_id}/text")
        if search_text_response.nil? || search_text_response.code.to_i != 200
          log "Search status failed, Status Code: #{search_text_response.code unless search_text_response.nil?}"
        end

        begin
          response = JSON.parse(search_text_response.body)
        rescue JSON::ParserError => e
          log "Error parsing search status response: #{e.message}"
          response = {}
        end

        if response["status"] && response["status"] == "success"
          processing_finished = true
        end
      end

      log("Get similarity result")
      @label1.text = "Searching..."
      @label2.text = "Getting result"
      @progressBar.setIndeterminate(true)

      search_response = send_rest_request("get", "#{get_search_url()}/#{@session_id}")
      if search_response.nil? || search_response.code.to_i != 200
        log "Search failed, Status Code: #{search_response.code unless search_response.nil?}"
        # TODO: reset GUI
        return
      end

      begin
        response = JSON.parse(search_response.body)
        log "Response found"
      rescue JSON::ParserError => e
        log "Error parsing search response: #{e.message}"
        response = {}
      end

      log("Found #{response.length} matches")
      @label1.text = "Parsing result (#{response.length} matches)"
      @label2.text = " "
      @progressBar.setIndeterminate(false)

      if response.length > 0
        max_similarity = 0

        values = response.values
        formatted_data = values.map do |value|
          name = value.keys[0]
          similarity = value.values[0].last.to_f

          if similarity > max_similarity
            max_similarity = similarity
          end

          [name, similarity]
        end

        log("Maximum similarity: #{max_similarity}")

        @label1.text = "Parsing result (#{response.length} matches)"
        @label2.text = "Sorting matches"
        @progressBar.setIndeterminate(true)

        # sort by similiarity
        @resultData = formatted_data.sort_by { |data| -data[1] }

        # initial value
        max_index = [@resultData.length - 1, 10].min
        threshold = @resultData[max_index][1]
        log "Set slider value"
        @resultSlider.setMaximum max_similarity * 100 * 100 + 1
        @resultSlider.setValue threshold * 100 * 100

        @progressBar.setIndeterminate(false)

        log("Generate image list")
        @resultDataSelected = @resultData.select { |data| data[1] >= threshold }.to_h
        log("Matches #{@resultDataSelected.length} items")

        @label2.text = "Render images"
        worker = ImageAdderWorker.new
        worker.frame = self
        worker.execute
      end

      @label1.text = " "
      @label2.text = " "
    rescue => e
      log "Error: #{e.message}"
    end
  end

  def stop_task
    @cancel_task = true
  end

  def get_logger
    @logger
  end

  def get_logging_worker
    @logging_worker
  end

  def get_keep_alive_thread
    @keep_alive_thread
  end

  def resize_image(buffered_image, max_width, max_height)
    width = buffered_image.get_width
    height = buffered_image.get_height

    if width > max_width || height > max_height
      width_ratio = max_width.to_f / width
      height_ratio = max_height.to_f / height
      scale_factor = [width_ratio, height_ratio].min
      new_width = (width * scale_factor).to_i
      new_height = (height * scale_factor).to_i
    else
      new_width = width
      new_height = height
    end

    if new_width <= 0
      new_width = 1
    end
    if new_height <= 0
      new_height = 1
    end

    # Create a new BufferedImage with the resized dimensions
    resized_image = BufferedImage.new(new_width, new_height, BufferedImage::TYPE_INT_ARGB)
    g = resized_image.create_graphics
    g.set_rendering_hint(java.awt.RenderingHints::KEY_INTERPOLATION, java.awt.RenderingHints::VALUE_INTERPOLATION_BILINEAR)
    g.draw_image(buffered_image, 0, 0, new_width, new_height, nil)

    resized_image
  end

  class LogWindowAdapter < WindowAdapter
    def windowClosing(event)
      frame = event.source

      if frame.instance_variable_get(:@task_running)
        option = JOptionPane.showConfirmDialog(nil, "Do you want to stop the running process?", "Confirm", JOptionPane::YES_NO_OPTION)

        if option == JOptionPane::YES_OPTION
          # stop the task only, no dispose!
          frame.stop_task
        end
      else
        frame.get_logging_worker.cancel(true)

        frame.get_keep_alive_thread.exit

        frame.get_logger.close

        # default is frame.default_close_operation = JFrame::DO_NOTHING_ON_CLOSE, but when no task is running,
        # dispose the frame manually
        frame.dispose
      end
    end
  end

  class LoggingWorker < SwingWorker
    attr_accessor :frame
    attr_accessor :logger

    def doInBackground
      while !cancelled
        begin
          log_queue = @frame.instance_variable_get(:@log_queue)
          message = log_queue.take
          publish(message)

          # Wait before printing the next item (1ms)
          sleep(0.001)

          # Skip log messages between for performance improvements
          @frame.clear_log
        rescue Exception => e
          @logger.error("Exception occurred while printing the log (#{e.class.canonical_name}): #{e.message}")
        end
      end
      puts "Logging Worker stopped!"
      nil
    end

    def process(chunks)
      log_text_pane = @frame.instance_variable_get(:@log_text_pane)

      position = log_text_pane.document.length
      chunks.each do |message|
        log_text_pane.document.insertString(position, message + "\n", nil)
        position = log_text_pane.document.length
      end
      log_text_pane.caret_position = position

      begin
        lines = log_text_pane.document.default_root_element.element_count
        if lines > MAX_LOG_LINES
          lines_to_remove = lines - MAX_LOG_LINES
          document = log_text_pane.styled_document
          root = document.default_root_element
          while lines_to_remove > 0 && root.element_count > 0
            line_start = root.getElement(0).start_offset
            line_end = root.getElement(0).end_offset
            document.remove(line_start, line_end - line_start)
            lines_to_remove -= 1
          end
        end
      rescue BadLocationException => ex
        @logger.error("Exception occurred while printing the log (#{ex.class.canonical_name}): #{ex.message}")
      end
    end
  end
end

# currently not used
class ResizeListener
  include ComponentListener

  def initialize(frame)
    @frame = frame
  end

  def componentResized(e)
    resultDataSelected = @frame.instance_variable_get(:@resultDataSelected)
    if !resultDataSelected.nil? && resultDataSelected.length > 0
      frame_width = @frame.get_width
      new_column_count = [frame_width / 150, 1].max # Adjust the divisor as needed
      @frame.log("Re-render with #{new_column_count} columns")

      # TODO: test start threaded when uncomment this resizelistener
      Thread.new do
        @frame.render_images(new_column_count)
      end
    end
  end

  def componentMoved(e); end
  def componentShown(e); end
  def componentHidden(e); end
end

class ImageAdderWorker < SwingWorker
  attr_accessor :frame

  def doInBackground
    @frame.log("Render image list")

    columns = 5
    panels = []
    filtered_data = @frame.instance_variable_get(:@resultDataSelected)

    @frame.instance_variable_set(:@task_running, true)
    @frame.instance_variable_set(:@cancel_task, false)

    @frame.instance_variable_get(:@label1).text = "Retrieving thumbnails"
    @frame.instance_variable_get(:@btn_show_in_workbench).setEnabled false
    @frame.instance_variable_get(:@btn_search).setEnabled false
    @frame.instance_variable_get(:@searchField).setEnabled false
    @frame.instance_variable_get(:@btn_filter).setEnabled false
    @frame.instance_variable_get(:@resultSlider).setEnabled false

    @frame.instance_variable_get(:@progressBar).setIndeterminate false
    @frame.instance_variable_get(:@progressBar).value = 0
    @frame.instance_variable_get(:@progressBar).maximum = filtered_data.length

    @frame.instance_variable_get(:@btn_cancel).setEnabled true

    @frame.instance_variable_get(:@resultThumbnailPane).removeAll
    @frame.instance_variable_get(:@resultThumbnailPane).revalidate
    @frame.instance_variable_get(:@resultThumbnailPane).repaint

    idx = 0
    filtered_data.each_pair do |guid, similarity|

      #@frame.log("Get thumbnail for item #{guid}")

      #nuix_item = @current_case.search("guid:#{guid}").first
      #img = nuix_item.getThumbnail().getPage(0)

      # use thumbnail from global list instead of querying dynamically
      img = @frame.instance_variable_get(:@item_thumbnails)[guid]
      if img
        buffered_image = img.getPageImage()
        if buffered_image.get_width > 0 && buffered_image.get_height > 0
          image = @frame.resize_image(buffered_image, 100, 100)

          c = GridBagConstraints.new
          c.gridwidth = 1
          c.anchor = GridBagConstraints::NORTHWEST
          c.insets = java.awt.Insets.new(5, 5, 5, 5) # Add padding if needed
          gridx = idx % columns
          c.gridx = gridx
          c.weightx = 1.0

          #if gridx == columns
          #  c.weightx = 1.0
          #end

          c.gridy = idx / columns

          if idx == filtered_data.length - 1
            c.weighty = 1.0
          end

          panel = JPanel.new(BorderLayout.new)
          image_icon = ImageIcon.new(image)
          image_label = JLabel.new(image_icon)

          label = (similarity * 100).round(2)
          text_label = JLabel.new("#{label}%")
          text_label.set_horizontal_alignment(JLabel::CENTER)

          panel.add(image_label, BorderLayout::CENTER)
          panel.add(text_label, BorderLayout::SOUTH)

          panels << [panel, c]

          if idx % 100 == 0
            publish(panels.clone)
            panels.clear
          end
        end
      end
      @frame.increase_progress(true)
      idx = idx + 1

      if @frame.instance_variable_get(:@cancel_task)
        @frame.log("Stopping image list generation!")
        break
      end
    end

    publish(panels.clone)

    nil
  end

  def process(chunks)
    @frame.log("Render chunk")

    resultThumbnailPane = @frame.instance_variable_get(:@resultThumbnailPane)
    chunks.each do |panels|
      panels.each do |data|
        panel = data[0]
        c = data[1]
        resultThumbnailPane.add(panel, c)
      end
    end
    resultThumbnailPane.revalidate
    resultThumbnailPane.repaint
  end

  def done
    begin
      get
    rescue Exception => e
      @frame.log("An Error occured #{e.message}")
    ensure
      @frame.instance_variable_get(:@resultSlider).setEnabled true
      @frame.instance_variable_get(:@btn_filter).setEnabled true
      @frame.instance_variable_get(:@searchField).setEnabled true
      @frame.instance_variable_get(:@btn_search).setEnabled true
      @frame.instance_variable_get(:@btn_show_in_workbench).setEnabled true
      @frame.instance_variable_get(:@btn_cancel).setEnabled false

      @frame.instance_variable_set(:@task_running, false)
      @frame.instance_variable_set(:@cancel_task, false)
    end
  end
end

begin
  if !File.exists? SETTINGS_FILE
    dialog = T3KSettingsDialog.new nil, SETTINGS_FILE
    dialog.setVisible true
  end
  nalvis_frame = NalvisFrame.new window, current_case, current_selected_items, utilities
  nalvis_frame.setVisible true
rescue StandardError => e
  JOptionPane.showMessageDialog(nil, "An error occurred: #{e.message}")
end

return 0
