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

require "json"
require "fileutils"
require "logger"
require "date"

java_import javax.swing.JFrame
java_import javax.swing.JPanel
java_import javax.swing.JLabel
java_import javax.swing.JButton
java_import javax.swing.JCheckBox
java_import javax.swing.border.EmptyBorder
java_import javax.swing.JProgressBar
java_import javax.swing.JScrollPane
java_import javax.swing.JTextPane
java_import java.awt.Font

java_import java.awt.event.WindowAdapter
java_import javax.swing.JOptionPane

java_import java.util.concurrent.LinkedBlockingDeque
java_import java.util.concurrent.LinkedBlockingQueue
java_import java.util.concurrent.Executors
java_import javax.swing.SwingUtilities
java_import javax.swing.SwingWorker

java_import javax.swing.JMenuBar
java_import javax.swing.JMenu
java_import javax.swing.JMenuItem

require_relative "metadata_profile_writer.rb"
require_relative "helper.rb"

class T3KAnalysisFrame < JFrame
  def initialize(window, current_case, current_selected_items, utilities, properties)
    super "T3K CORE classification"
    setDefaultCloseOperation JFrame::DO_NOTHING_ON_CLOSE

    @window = window
    @current_case = current_case
    @current_selected_items = current_selected_items
    @utilities = utilities
    @metadata_fields = {}

    @api_host = properties["api_host"]
    @api_port = properties["api_port"]
    @export_folder = properties["export_folder"]
    @srv_folder = properties["srv_folder"]
    @batch_size = properties["batch_size"].to_i
    
    case_location = @current_case.getLocation().getAbsolutePath
    log_file_path = File.join(case_location, "t3k-api_#{Time.now.strftime("%Y%m%d-%H%M%S")}.log")
    @logger = Logger.new(log_file_path)
    @logger::level = Logger::INFO

    panel = JPanel.new(java.awt.GridBagLayout.new)
    panel.setBorder(EmptyBorder.new(10, 10, 10, 10))

    gbC_labelh = java.awt.GridBagConstraints.new
    gbC_labelh.gridx = 0
    gbC_labelh.gridy = 1
    gbC_labelh.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_labelh.anchor = java.awt.GridBagConstraints::WEST
    gbC_labelh.insets = java.awt.Insets.new(5, 10, 5, 10)
    labelh = JLabel.new("Classify nuix items with T3K CORE")
    panel.add(labelh, gbC_labelh)

    gbc_chkbx_nalvis = java.awt.GridBagConstraints.new
    gbc_chkbx_nalvis.gridx = 0
    gbc_chkbx_nalvis.gridy = 2
    gbc_chkbx_nalvis.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_chkbx_nalvis.insets = java.awt.Insets.new(5, 10, 5, 10)
    @chkbx_nalvis = JCheckBox.new("Store NaLViS Encodings")
    @chkbx_nalvis.setSelected(true)
    @chkbx_nalvis.setEnabled(true)
    panel.add(@chkbx_nalvis, gbc_chkbx_nalvis)

    gbc_btn_start = java.awt.GridBagConstraints.new
    gbc_btn_start.gridx = 0
    gbc_btn_start.gridy = 4
    gbc_btn_start.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_start.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_start = JButton.new("Start Analysis")
    @btn_start.setEnabled(true)
    panel.add(@btn_start, gbc_btn_start)
	
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

    gbC_label3 = java.awt.GridBagConstraints.new
    gbC_label3.gridx = 1
    gbC_label3.gridy = 6
    gbC_label3.anchor = java.awt.GridBagConstraints::WEST
    gbC_label3.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label3 = JLabel.new(" ")
    panel.add(@label3, gbC_label3)

    gbC_label4 = java.awt.GridBagConstraints.new
    gbC_label4.gridx = 0
    gbC_label4.gridy = 7
    gbC_label4.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_label4.anchor = java.awt.GridBagConstraints::WEST
    gbC_label4.insets = java.awt.Insets.new(10, 10, 10, 10)
    @label4 = JLabel.new(" ")
    panel.add(@label4, gbC_label4)
	
    gridbagConstraints5 = java.awt.GridBagConstraints.new
    gridbagConstraints5.gridx = 0
    gridbagConstraints5.gridy = 8
    gridbagConstraints5.fill = java.awt.GridBagConstraints::HORIZONTAL
    gridbagConstraints5.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridbagConstraints5.weightx = 1.0
    gridbagConstraints5.insets = java.awt.Insets.new(5, 10, 5, 10)

    @progressBar = JProgressBar.new
    panel.add(@progressBar, gridbagConstraints5)

    gbc_btn_cancel = java.awt.GridBagConstraints.new
    gbc_btn_cancel.gridx = 0
    gbc_btn_cancel.gridy = 9
    gbc_btn_cancel.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_cancel.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_cancel = JButton.new("Cancel")
    @btn_cancel.setEnabled(false)
    panel.add(@btn_cancel, gbc_btn_cancel)

    gridBagConstraintsLogPane = GridBagConstraints.new
    gridBagConstraintsLogPane.gridx = 0
    gridBagConstraintsLogPane.gridy = 10
    gridBagConstraintsLogPane.fill = java.awt.GridBagConstraints::BOTH
    gridBagConstraintsLogPane.anchor = java.awt.GridBagConstraints::NORTHWEST
	  gridBagConstraintsLogPane.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridBagConstraintsLogPane.weightx = 1.0
    gridBagConstraintsLogPane.weighty = 1.0
	  gridBagConstraintsLogPane.insets = java.awt.Insets.new(0, 0, 0, 0)

    logPanel = JPanel.new(java.awt.GridBagLayout.new)
    panel.add(logPanel, gridBagConstraintsLogPane)

    gridBagConstraintsToggle = GridBagConstraints.new
    gridBagConstraintsToggle.gridx = 0
    gridBagConstraintsToggle.gridy = 0
    gridBagConstraintsToggle.anchor = java.awt.GridBagConstraints::SOUTHWEST
    gridBagConstraintsToggle.insets = java.awt.Insets.new(0, 10, 0, 0)
    gridBagConstraintsToggle.weightx = 1.0
    gridBagConstraintsToggle.weighty = 1.0

    log_toggle_btn = JToggleButton.new
    logPanel.add(log_toggle_btn, gridBagConstraintsToggle)

    log_toggle_btn.setText("▽  " + "Show Log");
    log_toggle_btn.addActionListener do |e|
      if @log_scroll_pane.isVisible()
        @log_scroll_pane.setVisible(false)
        log_toggle_btn.setText("▽  " + "Show Log")
        gridBagConstraintsToggle.weightx = 1.0
        gridBagConstraintsToggle.weighty = 1.0
        setMinimumSize(java.awt.Dimension.new(800, 200))
      else 
        @log_scroll_pane.setVisible(true)
        log_toggle_btn.setText("△  " + "Hide Log")
        gridBagConstraintsToggle.weightx = 0
        gridBagConstraintsToggle.weighty = 0
		    setMinimumSize(java.awt.Dimension.new(800, 600))
      end
      logPanel.remove(log_toggle_btn);
      logPanel.add(log_toggle_btn, gridBagConstraintsToggle)
      logPanel.revalidate()
      logPanel.repaint()
      setSize(java.awt.Dimension.new(getSize().width, getPreferredSize.height))
    end

    gbC_scrollPane = java.awt.GridBagConstraints.new
    gbC_scrollPane.gridx = 0
    gbC_scrollPane.gridy = 1
    gbC_scrollPane.fill = java.awt.GridBagConstraints::BOTH
    gbC_scrollPane.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbC_scrollPane.weightx = 1.0 # on resize expand
    gbC_scrollPane.weighty = 1.0 # on resize expand
    gbC_scrollPane.insets = java.awt.Insets.new(5, 10, 5, 10)

    @log_text_pane = JTextPane.new
    @log_text_pane.editable = false

    font = Font.new(Font::MONOSPACED, Font::PLAIN, 12)
    @log_text_pane.font = font

    @log_scroll_pane = JScrollPane.new
    @log_scroll_pane.setViewportView(@log_text_pane)
    @log_scroll_pane.setVisible(false);
    @log_scroll_pane.setPreferredSize java.awt.Dimension.new(@log_scroll_pane.getPreferredSize.width, 500)
    @log_scroll_pane.setMinimumSize @log_scroll_pane.getPreferredSize
    logPanel.add(@log_scroll_pane, gbC_scrollPane)

    setContentPane(panel)
    setMinimumSize(java.awt.Dimension.new(800, 200))
    pack

    @task_running = false
    @cancel_task = false
    @task_finished = false

    add_window_listener(LogWindowAdapter.new)

    @btn_start.addActionListener do |e|
      @logger.info("action")
      t1 = Thread.new do
        begin
          @task_running = true
          @btn_start.setEnabled false
          @chkbx_nalvis.setEnabled false
          @btn_cancel.setEnabled true

          classify()

          # Clear remaining messages and print last messages only
          clear_log()

          log("- Done -")

          if @cancel_task
            log("Action was cancelled!")
          end
          log("Action is exited.")
        rescue StandardError => e
          @logger.error("An error occurred: #{e.message}")
          JOptionPane.showMessageDialog(self, "An error occured: #{e.message}")
        ensure
          @task_running = false
          @cancel_task = false
          @task_finished = true
          @btn_cancel.setEnabled false
        end
      end
    end

    @btn_cancel.addActionListener do |e|
      option = JOptionPane.showConfirmDialog(nil, "Do you want to stop the running process?", "Confirm", JOptionPane::YES_NO_OPTION)

      if option == JOptionPane::YES_OPTION
        stop_task
      end
    end
	
    @log_queue = LinkedBlockingDeque.new
    @logging_worker = LoggingWorker.new
    @logging_worker.frame = self
    @logging_worker.logger = @logger
    @logging_worker.execute


    @result_queue = LinkedBlockingQueue.new
    num_threads = java.lang.Runtime.getRuntime.available_processors
    @result_executor = Executors.new_fixed_thread_pool(num_threads)

    runnable = java.lang.Runnable.impl do
      loop do
        begin

          data = @result_queue.take
          begin
            if data[:type] == 'error'
              log("Save failed items information (#{data[:cat]}) for #{data[:item][:guid]}")
              update_custom_metadata_for_failed_item(data[:item], data[:cat])
            elsif data[:type] == 'success'
              log("Save classification for item #{data[:item][:guid]}")
              nuix_item = @current_case.search("guid:#{data[:item][:guid]}").first
              data[:item][:tags].each do |tag|
                nuix_item.addTag(tag)
              end
              data[:item][:custom_metadata].each_pair do |key, value|
                nuix_item.getCustomMetadata[key] = value
              end
            end
          rescue StandardError => e
            log("Save classification error: #{e.message}")
            log(data)
          end
        rescue StandardError => e
          log("An error occurred with the classification loop: #{e.message}")
        end
      end
    end

    @result_executor.submit(runnable)
    
  end

  def get_upload_url()
    "http://#{@api_host}:#{@api_port}/upload"
  end

  def get_poll_url()
    "http://#{@api_host}:#{@api_port}/poll"
  end

  def get_result_url()
    "http://#{@api_host}:#{@api_port}/result"
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
  
  def increase_progress()
    @progressBar.value = @progressBar.value + 1
    @label4.text = "Item #{@progressBar.value}/#{@progressBar.maximum} (#{((@progressBar.value.to_f/@progressBar.maximum)*100).round(0)}%)"
  end

  def classify()
    items = @current_selected_items
    begin
      nuix_case = @current_case
      exporter = @utilities.getBinaryExporter

      # Create a timestamped folder
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      timestamped_folder = "#{@export_folder}/#{timestamp}"
      FileUtils.mkdir_p(timestamped_folder)

      log("Starting classification of #{items.size} items")

      # Process each item in the batch
      batch_number = 0
      total_batches = (items.length / @batch_size.to_f).ceil

      @label1.text = "Phase 1/#{PHASES_ANALYSIS}: Exporting and classify items in batches"
      @progressBar.maximum = items.length
      @label4.text = "Item #{@progressBar.value}/#{@progressBar.maximum} (#{((@progressBar.value.to_f/@progressBar.maximum)*100).round(0)}%)"

      items.each_slice(@batch_size) do |batch|
        start = Time.now
        if @cancel_task
          log("Stopping batch!")
          break
        end

        log("=============================================================")
        batch_number += 1
        log "Processing batch #{batch_number} of #{total_batches}"
        @label2.text = "Batch #{batch_number}/#{total_batches}"

        # Export files and store paths
        log("Exporting files to #{timestamped_folder}")
        exported_items = {}
        batch.each do |item|
          log("Exporting file #{item.getGuid()}.#{item.getCorrectedExtension()}")
          exported_file_path = "#{timestamped_folder}/#{item.getGuid()}.#{item.getCorrectedExtension()}"
          begin
            exporter.exportItem(item, exported_file_path)
          rescue => e
            log "Error exporting item: #{e.message}"
          end

          if File.exist?(exported_file_path)
            log("Export successfully")
            item_srv_path = "#{@srv_folder}/#{timestamp}/#{item.getGuid()}.#{item.getCorrectedExtension()}"
            exported_items[item_srv_path] = { 'guid': item.getGuid(), 'item_srv_path': item_srv_path, 'exported_file_path': exported_file_path }
          else
            @result_queue.offer({ 'type': 'error', 'cat': 'Export', 'item': {'guid': item.getGuid() }})
            log("Failed to export #{item.getGuid}")
            increase_progress()
          end

          if @cancel_task
            log("Stopping task!")
            break
          end
        end

        if exported_items.size > 0
          # Uploading files in batch mode
          log("Uploading batch...")
          uploaded_items = {}
          upload_payload = {}
          exported_items.each do |item_srv_path, data|
            upload_payload[data[:guid]] = "#{item_srv_path}"
          end
          log("Upload Payload: #{upload_payload}")
          upload_response = send_rest_request("post", get_upload_url(), upload_payload)

          if upload_response.nil? || upload_response.code.to_i != 201
            log "Upload failed for batch, Status Code: #{upload_response.code unless upload_response.nil?}"

            # Clean up the exported item files as upload failed
            exported_items.each { |item_srv_path, data| delete_file(data[:exported_file_path]) }

            # Track all items in the batch as export failed
            batch.each do |item|
              @result_queue.offer({ 'type': 'error', 'cat': 'Upload', 'item': {'guid': item.getGuid(), 'response': upload_response }})
            end

            next # Skip the rest of the loop for this batch and continue to the next batch
          end

          begin
            upload_ids = JSON.parse(upload_response.body)
          rescue JSON::ParserError => e
            log "Error parsing upload response: #{e.message}"
            upload_ids = {}
          end
          #log("Upload IDs: #{upload_ids}")

          # Map upload ids to items
          log("Map upload_ids to items")
          upload_ids.each do |upload_id, item_srv_path|
            if exported_items.key?(item_srv_path)
              log("Item #{upload_id} is uploaded")
              uploaded_items[item_srv_path] = { "guid": exported_items[item_srv_path][:guid], "upload_id": upload_id, "exported_file_path": exported_items[item_srv_path][:exported_file_path], "finished": false }
            else
              @logger.error("Item #{upload_id} is not found as export?!")
              log("Item #{upload_id} is not found as export?!")
            end
          end

          log("Uploaded items")

          # Poll the API until all items which are uploaded are finished processing
          log("Polling uploaded items and get result")
          all_items_finished = false
          until all_items_finished || @cancel_task
            all_items_finished = uploaded_items.all? do |item_srv_path, item_data|
              uploaded_items[item_srv_path][:finished]
            end

            uploaded_items.each do |item_srv_path, item_data|
              if @cancel_task
                log("Stopping task!")
                break
              end

              if uploaded_items[item_srv_path][:finished]
                next
              end

              item_result_extracted = getItemResult(item_srv_path, item_data)
              log("Item #{item_data[:upload_id]} Result: #{item_result_extracted}")
              uploaded_items[item_srv_path][:finished] = item_result_extracted
            end

            if POLLING_INTERVAL
              sleep(POLLING_INTERVAL)
            end
          end
        end
        finish = Time.now
        @label3.text = "Batch #{batch_number} processed in #{format_duration(finish - start)}"
      end

      # delete folder? => not working, deleting files is to slow
      #log("Try to delete folder #{timestamped_folder}")
      #log(Dir.entries(timestamped_folder))
      #FileUtils.remove_dir(timestamped_folder) if Dir.empty?(timestamped_folder)

      log("Finished!")
    rescue => e
      log "A fatal Error occurred: #{e.message}"
      log e
    end
    @label1.text = " "
    @label2.text = " "
    @label3.text = " "
    @label4.text = " "
    @cancel_task = false
    log("=============================================================")

    log("Analyze is complete, Remaining items in classification queue: #{@result_queue.size}")
    @label1.text = "Save classifications on nuix items"
    @progressBar.maximum = 0
    @progressBar.value = 0
    @progressBar.setIndeterminate(true)

    # wait for classification is done (@result_queue.size == 0)
    while @result_queue.size > 0 and not @cancel_task
      @label2.text = "#{@result_queue.size} items remaining"
      sleep(1)
    end
    # then stop @result_executor
    @result_executor.shutdown

    @progressBar.setIndeterminate(false)

    log("Classification is done")

    # Write Metadataprofile
    log("Found metadata fields")
    log(@metadata_fields)
    mdp_utility = MetadataProfileReaderWriter.new @current_case
    mdp_utility.writeProfile("T3K Result", @metadata_fields)

    # Open metadataprofile
    metadatastore = @current_case.getMetadataProfileStore()
    metadataprofile = metadatastore.getMetadataProfile("T3K Result")
    if metadataprofile
      # @window.closeAllTabs
      source_guids = items.map { |item| item.guid }.compact
      guid_search = "guid:(#{source_guids.join " OR "})"
      @window.openTab "workbench", { "search" => guid_search, "metadataProfile" => metadataprofile }
    end
    # Reset progressbar
    @progressBar.maximum = 0
    @progressBar.value = 0
    @label1.text = " "
    @label2.text = " "
    @label3.text = " "
    @label4.text = " "
  end

  def getItemResult(item_srv_path, item_data)
    upload_id = item_data[:upload_id]
    log("Item #{upload_id}: Polling")
    poll_response = send_rest_request("get", "#{get_poll_url()}/#{upload_id}")

    if poll_response.nil? || poll_response.code.to_i != 200
      log "Item #{upload_id}: Polling failed for item: #{item_data[:guid]}, Status Code: #{poll_response.code unless poll_response.nil?}"
      @result_queue.offer({ 'type': 'error', 'cat': 'PollQuery', 'item': {'guid': item_data[:guid], 'response': poll_response }})
      delete_file(item_data[:exported_file_path])
      increase_progress()
      return true # Mark the item as finished
    else
      begin
        poll_result = JSON.parse(poll_response.body)
      rescue JSON::ParserError => e
        log "Item #{upload_id}: Error parsing poll response: #{e.message}"
        poll_result = {}
      end

      log("Item #{upload_id}: Polling Result: #{poll_result}")

      unless poll_result["finished"]
        #log "Item #{upload_id}: Not ready: #{item_data[:guid]}"
        return false # Mark the item as not finished and continue polling
      else
        log("Item #{upload_id}: Polling finished -> Get Result")

        log("Item #{upload_id}: Reading result for item #{upload_id}")
        result_response = send_rest_request("get", "#{get_result_url()}/#{upload_id}")

        # Check if the result response is successful (HTTP code 200)
        if result_response.nil? || result_response.code.to_i != 200
          log "Item #{upload_id}: Result retrieval failed for item: #{item_data[:guid]}, Status Code: #{result_response.code unless result_response.nil?}"
          @result_queue.offer({ 'type': 'error', 'cat': 'ResultQuery', 'item': {'guid': item_data[:guid], 'response': result_response }})
          delete_file(item_data[:exported_file_path])
          increase_progress()
          return true # Mark the item as finished
        end

        # Parse the JSON response for result
        begin
          result_data = JSON.parse(result_response.body)
        rescue JSON::ParserError => e
          log "Item #{upload_id}: Error parsing result response: #{e.message}"
          result_data = {}
        end

        #log("Item #{upload_id}: Result: #{result_data}")
        log("Item #{upload_id}: Result found")

        if !result_data.empty?
          parseResult(result_data, item_data[:guid])
        else
          log "Item #{upload_id}: Result body failed for item: #{item_data[:guid]}}"
          @result_queue.offer({ 'type': 'error', 'cat': 'Result', 'item': {'guid': item_data[:guid], 'response': result_response }})
        end

        delete_file(item_data[:exported_file_path])
        increase_progress()
        return true # Mark the item as finished
      end
    end
  end

  def delete_file(path)
    log("Deleting file #{path}")
    begin
      FileUtils.remove_file(path) if File.exist?(path)
    rescue => e
      log "Error deleting file #{path}: #{e.message}"
    end
  end

  def update_custom_metadata_for_failed_item(item_data, error_type)
      nuix_item = @current_case.search("guid:#{item_data[:guid]}").first
      
      nuix_item.addTag("#{CUSTOM_METADATA_FIELD_NAME}|Errors|#{error_type}")
      
      error_msg = "Failed to process the item"
      unless item_data[:response].nil?
        error_msg = "#{error_msg}, Status: #{item_data[:response].code}, Body: #{item_data[:response].body}"
      end
        nuix_item.getCustomMetadata["#{CUSTOM_METADATA_FIELD_NAME}|Error|#{error_type}"] = error_msg
  end

  def parseResult(result_data, nuix_item_guid)
    result = { 'type': 'success', 'cat': 'Result', 'item': { "guid": nuix_item_guid, "tags": [], "custom_metadata": {} }}

    metadata = result_data["metadata"]
    result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|RAW|Metadata"] = metadata.to_json

    detections = result_data["detections"]

    detection_count = 0
    all_detections = []
    all_detections_max_score = {}
    detections.each_pair do |detection_idx, detection|
      if detection.size > 0
        detection_count += 1
        
        #detection.each_pair do |key, value|
        #  result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|RAW|AllResults|#{detection_idx}|#{key}"] = value.to_s
        #end

        info = nil
        type = nil
        score = nil
        description = nil
        case detection["type"]
        when "age/gender"
          #log "Person detected!"
          gender = detection["gender_string"]
          age = detection["age"]
          info = "Person #{detection["info"]}"
          type = "person|#{gender}|#{age}"
          score = (detection["score"] * 100).round(1)
        when "object"
          #log "Object detected!"
          info = detection["class_name"]
          type = "object|#{info}"
          score = (detection["score"] * 100).round(1)
        when "CCR"
          #log "CCR detected"
          info = detection["info"]
          type = "CCR|#{info}"
          score = (detection["similarity"] * 100).round(1)
        when "metaclassifier"
          #log "Metaclassifier detected"
          info = detection["label"]
          type = "Metaclassifier|#{info}"
          score = (detection["score"] * 100).round(1)
        when "face"
          #log "Face detected"
          info = "Face #{detection["info"]}"
          type = "Face|#{info}"
          score = (detection["score"] * 100).round(1)
        when "md5"
          #log "MD5 match detected"
          info = "MD5 #{detection["info"]}"
          type = "MD5"
          description = detection["description"]
        when "photoDNA"
          #log "photoDNA match detected"
          info = "PhotoDNA #{detection["info"]}"
          type = "PhotoDNA"
          description = detection["description"]
        when "OCR"
          #log "OCR match detected"
          info = "OCR #{detection["info"]}"
          type = "OCR"
          description = detection["description"]
        when "text"
          #log "Text match detected"
          info = "Text #{detection["info"]}"
          type = "Text"
          description = detection["description"]
        when "pattern"
          #log "Pattern match detected"
          info = "Pattern #{detection["info"]}"
          type = "Pattern"
          description = detection["name"]
        when "ALPR"
          #log "License Plate match detected"
          info = "License Plate"
          type = "License Plate"
          description = "#{detection["description"]}: #{detection["info"]}"
        else
          #log "Unknown type detected"
          info = "Unknown"
          type = "Unknown"
          description = "Unknown"
        end

        if score
          
          percentage_ranges = [
            { range: (0..10), tag: "0-10%" },
            { range: (10..20), tag: "10-20%" },
            { range: (20..30), tag: "20-30%" },
            { range: (30..40), tag: "30-40%" },
            { range: (40..50), tag: "40-50%" },
            { range: (50..60), tag: "50-60%" },
            { range: (60..70), tag: "60-70%" },
            { range: (70..80), tag: "70-80%" },
            { range: (80..90), tag: "80-90%" },
            { range: (90..95), tag: "90-95%" },
            { range: (95..100), tag: "95-100%" },
          ]

          selected_range = percentage_ranges.find { |range| range[:range].cover?(score) }

          if selected_range
            result[:item][:tags] << "#{CUSTOM_METADATA_FIELD_NAME}|Scores|#{selected_range[:tag]}|#{score}%"

            # store info as tag
            result[:item][:tags] << "#{CUSTOM_METADATA_FIELD_NAME}|Results|#{type}|#{selected_range[:tag]}|#{score}%"
          end
        end

        if info && score
          all_detections.append("#{info} - #{score}%")

          # store max score for this detection type of the object
          if all_detections_max_score.key?(info)
            all_detections_max_score[info] = [all_detections_max_score[info], score].max
          else
            all_detections_max_score[info] = score
          end
        end

        if info && description

          # store description as tag
          result[:item][:tags] << "#{CUSTOM_METADATA_FIELD_NAME}|Results|#{type}|#{description}"

          all_detections.append("#{info} - #{description}")
          # append to this detection type of the object
          if all_detections_max_score.key?(type)
            all_detections_max_score[type] = all_detections_max_score[type] + "\n" + description
          else
            all_detections_max_score[type] = description
          end
        end

        if !info && !score && !description
          log "Error with the detections!!"
          result[:item][:tags] << "#{CUSTOM_METADATA_FIELD_NAME}|Error|DetectionError"
        end
      else
        #log "Nothing detected"
        result[:item][:tags] << "#{CUSTOM_METADATA_FIELD_NAME}|Nothing detected"
      end
    end

    # store max score for this type of detection
    all_detections_max_score.each_pair do |info, score|
      metadatafield = "#{CUSTOM_METADATA_FIELD_NAME}|Result|#{info}"

      result[:item][:custom_metadata][metadatafield] = score

      # append as metadata column for metadataprofile
      if !@metadata_fields.key?(metadatafield)
        @metadata_fields[metadatafield] = info
      end
    end

    # Set custom metadata on the item
    # store all types of detections in one field
    result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|Detections"] = all_detections.join("\n")
    result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|Count"] = detection_count
    result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|RAW|Detections"] = detections.to_json

    # NaLViS encodings
    if @chkbx_nalvis.isSelected && result_data.has_key?("nalvis_result")
      nalvis_result = result_data["nalvis_result"]
      result[:item][:custom_metadata]["#{CUSTOM_METADATA_FIELD_NAME}|nalvis"] = nalvis_result.to_json
    end

    @result_queue.offer(result)
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

      @logger.info("Starting Logging Worker")

      while !cancelled
        begin
          log_queue = @frame.instance_variable_get(:@log_queue)
          message = log_queue.take
          publish(message)

          # Wait before printing the next item (1ms)
          sleep(0.001)

          # Skip log messages between for performance improvements
          @frame.clear_log

          task_finished = @frame.instance_variable_get(:@task_finished)
          if log_queue.size == 0 and task_finished
            cancel(true)
          end

        rescue Exception => e
          @logger.error("Exception occurred while printing the log (#{e.class.canonical_name}): #{e.message}")
        end
      end
      @logger.info('Logging Worker stopped!')
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
        if lines > MAX_LINES
          lines_to_remove = lines - MAX_LINES
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
        logger.error("Exception occurred while printing the log (#{ex.class.canonical_name}): #{ex.message}")
      end
    end
  end
end