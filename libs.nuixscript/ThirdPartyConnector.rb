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

require "fileutils"
require "logger"
require "date"

require "stringio"

java_import javax.swing.JFrame
java_import javax.swing.JPanel
java_import javax.swing.JLabel
java_import javax.swing.JButton
java_import javax.swing.JCheckBox
java_import javax.swing.JToggleButton
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

require_relative "helper.rb"
require_relative "settings_dialog.rb"

class ThirdPartyConnector < JFrame
  def initialize(window, current_case, current_selected_items, utilities)
    super ""
    setDefaultCloseOperation JFrame::DO_NOTHING_ON_CLOSE

    @window = window
    @current_case = current_case
    @current_selected_items = current_selected_items
    @utilities = utilities
    @metadata_fields = {}

    properties = read_properties SETTINGS_FILE

    @api_host = properties["api_host"]
    @api_port = properties["api_port"]
    @export_folder = properties["export_folder"]
    @srv_folder = properties["srv_folder"]
    @batch_size = properties["batch_size"].to_i
    @custom_metadata_field_name = properties["metadata_name"]

    case_location = @current_case.getLocation().getAbsolutePath
    log_file_path = File.join(case_location, "api_#{Time.now.strftime("%Y%m%d-%H%M%S")}.log")
    @logger = Logger.new(log_file_path)
    @logger::level = Logger::INFO

    @panel = JPanel.new(java.awt.GridBagLayout.new)
    @panel.setBorder(EmptyBorder.new(10, 10, 10, 10))

    gbC_labelh = java.awt.GridBagConstraints.new
    gbC_labelh.gridx = 0
    gbC_labelh.gridy = 1
    gbC_labelh.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_labelh.anchor = java.awt.GridBagConstraints::WEST
    gbC_labelh.insets = java.awt.Insets.new(5, 10, 5, 10)
    labelh = JLabel.new("Analyse Nuix Items")
    @panel.add(labelh, gbC_labelh)

    gbc_btn_start = java.awt.GridBagConstraints.new
    gbc_btn_start.gridx = 0
    gbc_btn_start.gridy = 4
    gbc_btn_start.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_start.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_start = JButton.new("Start Analysis")
    @btn_start.setEnabled(true)
    @panel.add(@btn_start, gbc_btn_start)

    gbC_label1 = java.awt.GridBagConstraints.new
    gbC_label1.gridx = 0
    gbC_label1.gridy = 5
    gbC_label1.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_label1.anchor = java.awt.GridBagConstraints::WEST
    gbC_label1.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label1 = JLabel.new(" ")
    @panel.add(@label1, gbC_label1)

    gbC_label2 = java.awt.GridBagConstraints.new
    gbC_label2.gridx = 0
    gbC_label2.gridy = 6
    gbC_label2.anchor = java.awt.GridBagConstraints::WEST
    gbC_label2.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label2 = JLabel.new(" ")
    @panel.add(@label2, gbC_label2)

    gbC_label3 = java.awt.GridBagConstraints.new
    gbC_label3.gridx = 1
    gbC_label3.gridy = 6
    gbC_label3.anchor = java.awt.GridBagConstraints::WEST
    gbC_label3.insets = java.awt.Insets.new(5, 10, 5, 10)
    @label3 = JLabel.new(" ")
    @panel.add(@label3, gbC_label3)

    gbC_label4 = java.awt.GridBagConstraints.new
    gbC_label4.gridx = 0
    gbC_label4.gridy = 7
    gbC_label4.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gbC_label4.anchor = java.awt.GridBagConstraints::WEST
    gbC_label4.insets = java.awt.Insets.new(10, 10, 10, 10)
    @label4 = JLabel.new(" ")
    @panel.add(@label4, gbC_label4)

    gridbagConstraints5 = java.awt.GridBagConstraints.new
    gridbagConstraints5.gridx = 0
    gridbagConstraints5.gridy = 8
    gridbagConstraints5.fill = java.awt.GridBagConstraints::HORIZONTAL
    gridbagConstraints5.gridwidth = java.awt.GridBagConstraints::REMAINDER
    gridbagConstraints5.weightx = 1.0
    gridbagConstraints5.insets = java.awt.Insets.new(5, 10, 5, 10)

    @progressBar = JProgressBar.new
    @panel.add(@progressBar, gridbagConstraints5)

    gbc_btn_cancel = java.awt.GridBagConstraints.new
    gbc_btn_cancel.gridx = 0
    gbc_btn_cancel.gridy = 9
    gbc_btn_cancel.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_btn_cancel.insets = java.awt.Insets.new(5, 10, 5, 10)
    @btn_cancel = JButton.new("Cancel")
    @btn_cancel.setEnabled(false)
    @panel.add(@btn_cancel, gbc_btn_cancel)

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
    @panel.add(logPanel, gridBagConstraintsLogPane)

    gridBagConstraintsToggle = GridBagConstraints.new
    gridBagConstraintsToggle.gridx = 0
    gridBagConstraintsToggle.gridy = 0
    gridBagConstraintsToggle.anchor = java.awt.GridBagConstraints::SOUTHWEST
    gridBagConstraintsToggle.insets = java.awt.Insets.new(0, 10, 0, 0)
    gridBagConstraintsToggle.weightx = 1.0
    gridBagConstraintsToggle.weighty = 1.0

    log_toggle_btn = JToggleButton.new
    logPanel.add(log_toggle_btn, gridBagConstraintsToggle)

    log_toggle_btn.setText("Show Log")
    log_toggle_btn.addActionListener do |e|
      if @log_scroll_pane.isVisible()
        @log_scroll_pane.setVisible(false)
        log_toggle_btn.setText("Show Log")
        gridBagConstraintsToggle.weightx = 1.0
        gridBagConstraintsToggle.weighty = 1.0
        setMinimumSize(java.awt.Dimension.new(800, 200))
      else
        @log_scroll_pane.setVisible(true)
        log_toggle_btn.setText("Hide Log")
        gridBagConstraintsToggle.weightx = 0
        gridBagConstraintsToggle.weighty = 0
        setMinimumSize(java.awt.Dimension.new(800, 600))
      end
      logPanel.remove(log_toggle_btn)
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
    @log_scroll_pane.setVisible(false)
    @log_scroll_pane.setPreferredSize java.awt.Dimension.new(@log_scroll_pane.getPreferredSize.width, 500)
    @log_scroll_pane.setMinimumSize @log_scroll_pane.getPreferredSize
    logPanel.add(@log_scroll_pane, gbC_scrollPane)

    menu_bar = JMenuBar.new
    settings_menu = JMenu.new("Settings")
    settings_item = JMenuItem.new("Settings")
    settings_item.addActionListener do |event|
      showSettings()
    end
    settings_menu.add(settings_item)
    menu_bar.add(settings_menu)
    setJMenuBar(menu_bar)

    setContentPane(@panel)
    setMinimumSize(java.awt.Dimension.new(800, 200))
    pack

    @items_to_disable = [@btn_start]

    @task_running = false
    @cancel_task = false
    @task_finished = false

    add_window_listener(LogWindowAdapter.new)

    @btn_start.addActionListener do |e|
      @logger.info("action")
      t1 = Thread.new do
        begin
          @task_running = true
          @items_to_disable.each do |el|
            el.setEnabled false
          end
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
    
    @result_mutex = Mutex.new
    @result_remaining_items = 0
    @result_finished = false

    runnable = java.lang.Runnable.impl do
      loop do
        begin

          shutdown = false
          
          @result_mutex.synchronize do
            if @result_finished and @result_queue.size == 0
              shutdown = true
            end
          end
          
          break if shutdown
        
          data = @result_queue.poll
          if data
            @result_mutex.synchronize do
              @result_remaining_items += 1
            end

            begin
              if data[:type] == "error"
                log("Save failed items information (#{data[:cat]}) for #{data[:item][:guid]}")
                update_custom_metadata_for_failed_item(data[:item], data[:cat])
              elsif data[:type] == "success"
                log("Save results for item #{data[:item][:guid]}")
                nuix_item = @current_case.search("guid:#{data[:item][:guid]}").first
                data[:item][:tags].each do |tag|
                  nuix_item.addTag(tag)
                end
                #log data
                if data[:item].key?(:custom_metadata)
                  data[:item][:custom_metadata].each_pair do |key, value|
                    #nuix_item.getCustomMetadata[key.to_s] = value
                    nuix_item.getCustomMetadata.putText(key.to_s, value)
                  end
                end
              end
            rescue StandardError => e
              log("Save results error: #{e.message}")
              log(data)
              log e.backtrace.join("\n")
            end

            @result_mutex.synchronize do
              @result_remaining_items -= 1
            end

          end
        rescue StandardError => e
          log("An error occurred with the results loop: #{e.message}")
        end
      end
    end

    #@result_executor.submit(runnable)
    num_threads.times do 
      @result_executor.submit(runnable)
    end
  end

  def showSettings
    dialog = SettingsDialog.new self, SETTINGS_FILE
    dialog.setVisible true
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
    setProgressBarValue @progressBar.value + 1
    setLabel4 "Item #{@progressBar.value}/#{@progressBar.maximum} (#{((@progressBar.value.to_f / @progressBar.maximum) * 100).round(0)}%)"
  end

  def setLabel1(text)
    @label1.text = text
  end

  def setLabel2(text)
    @label2.text = text
  end

  def setLabel3(text)
    @label3.text = text
  end

  def setLabel4(text)
    @label4.text = text
  end

  def setProgressBarMax(value)
    @progressBar.maximum = value
  end

  def setProgressBarValue(value)
    @progressBar.value = value
  end

  def classify()
    items = @current_selected_items
    begin
      nuix_case = @current_case
      exporter = @utilities.getBinaryExporter
      annotater = @utilities.getBulkAnnotater
      
      annotater.addTag("#{@custom_metadata_field_name}|Overview|Selected", items)

      # Create a timestamped folder
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      timestamped_folder = "#{@export_folder}/#{timestamp}"
      FileUtils.mkdir_p(timestamped_folder)

      log("Starting classification of #{items.size} items")

      # Process each item in the batch
      batch_number = 0
      total_batches = (items.length / @batch_size.to_f).ceil

      setLabel1 "Phase 1/3: Exporting and classify items in batches"
      setProgressBarMax items.length
      setLabel4 "Item #{@progressBar.value}/#{@progressBar.maximum} (#{((@progressBar.value.to_f / @progressBar.maximum) * 100).round(0)}%)"

      items.each_slice(@batch_size) do |batch|
        start = Time.now
        if @cancel_task
          log("Stopping batch!")
          break
        end

        log("=============================================================")
        batch_number += 1
        log "Processing batch #{batch_number} of #{total_batches}"
        setLabel2 "Batch #{batch_number}/#{total_batches}"

        # Export files and store paths
        log("Exporting files to #{timestamped_folder}")
        exported_items = {}
        batch.each do |item|
          #@result_queue.offer({ 'type': "success", 'cat': "Select", 'item': { "guid": item.getGuid(), "tags": ["#{@custom_metadata_field_name}|Overview|Selected"] } })

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
            @result_queue.offer({ 'type': "error", 'cat': "Export", 'item': { 'guid': item.getGuid() } })
            log("Failed to export #{item.getGuid}")
            increase_progress()
          end

          if @cancel_task
            log("Stopping task!")
            break
          end
        end

        if exported_items.size > 0
          log("Uploaded items")
          result = upload_batch(batch, exported_items)

          if result == false
            next # Skip the rest of the loop for this batch and continue to the next batch
          end
        end
        finish = Time.now
        setLabel3 "Batch #{batch_number} processed in #{format_duration(finish - start)}"
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
    setLabel1 " "
    setLabel2 " "
    setLabel3 " "
    setLabel4 " "
    @cancel_task = false
    log("=============================================================")

    log("Analyze is complete, Remaining items in classification queue: #{@result_queue.size+@result_remaining_items}")
    setLabel1 "Save classifications on nuix items"
    setProgressBarMax 0
    setProgressBarValue 0
    @progressBar.setIndeterminate(true)

    # wait for classification is done (@result_queue.size == 0)
    while (@result_queue.size > 0 or @result_remaining_items > 0) and not @cancel_task
      setLabel2 "#{@result_queue.size+@result_remaining_items} items remaining"
      sleep(1)
    end
    # then stop @result_executor
    @result_finished = true
    @result_executor.shutdown
    @result_executor.await_termination(1, java.util.concurrent.TimeUnit::MINUTES)

    @progressBar.setIndeterminate(false)

    log("Classification is done")

    finalize(items)

    # Reset progressbar
    setProgressBarMax 0
    setProgressBarValue 0
    setLabel1 " "
    setLabel2 " "
    setLabel3 " "
    setLabel4 " "
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

    nuix_item.addTag("#{@custom_metadata_field_name}|Errors|#{error_type}")

    error_msg = "Failed to process the item"
    unless item_data[:response].nil?
      error_msg = "#{error_msg}, Status: #{item_data[:response].code}, Body: #{item_data[:response].body}"
    end
    nuix_item.getCustomMetadata["#{@custom_metadata_field_name}|Error|#{error_type}"] = error_msg
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

  def upload_batch
    raise "implementation needed"
  end

  def finalize(items)
    raise "implementation needed"
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
      @logger.info("Logging Worker stopped!")
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
        logger.error("Exception occurred while printing the log (#{ex.class.canonical_name}): #{ex.message}")
      end
    end
  end
end
