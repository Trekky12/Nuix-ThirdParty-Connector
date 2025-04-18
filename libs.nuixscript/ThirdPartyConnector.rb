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


java_import java.util.concurrent.LinkedBlockingQueue
java_import java.util.concurrent.Executors

require_relative "helper.rb"
require_relative "settings_dialog.rb"

class ThirdPartyConnector
  def initialize(current_case, current_selected_items, utilities, settings_file)

    @frame = nil
    @current_case = current_case
    @current_selected_items = current_selected_items
    @utilities = utilities

    @properties = read_properties settings_file

    case_location = @current_case.getLocation().getAbsolutePath
    log_file_path = File.join(case_location, "api_#{Time.now.strftime("%Y%m%d-%H%M%S")}.log")
    @logger = Logger.new(log_file_path)
    @logger::level = Logger::INFO


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
            if @result_finished
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

  def classify()
    items = @current_selected_items
    begin
      nuix_case = @current_case
      exporter = get_exporter()
      annotater = @utilities.getBulkAnnotater
      
      annotater.addTag("#{@properties["metadata_name"]}|Overview|Selected", items)

      # Create a timestamped folder
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      timestamped_folder = "#{@properties["export_folder"]}/#{timestamp}"
      FileUtils.mkdir_p(timestamped_folder)

      log("Starting classification of #{items.size} items")

      # Process each item in the batch
      batch_number = 0
      total_batches = (items.length / @properties["batch_size"].to_f).ceil

      @frame&.setLabel1 "Phase 1/3: Exporting and classify items in batches"
      @frame&.instance_variable_get(:@progressBar).maximum = items.length if @frame
      @frame&.setLabel4 "Item #{@frame.instance_variable_get(:@progressBar).value}/#{@frame.instance_variable_get(:@progressBar).maximum} (#{((@frame.instance_variable_get(:@progressBar).value.to_f / @frame.instance_variable_get(:@progressBar).maximum) * 100).round(0)}%)"

      items.each_slice(@properties["batch_size"].to_i) do |batch|
        start = Time.now
        if @frame&.is_task_cancelled?
          log("Stopping batch!")
          break
        end

        log("=============================================================")
        batch_number += 1
        log "Processing batch #{batch_number} of #{total_batches}"
        @frame&.setLabel2 "Batch #{batch_number}/#{total_batches}"

        # Export files and store paths
        log("Exporting files to #{timestamped_folder}")
        exported_items = {}
        batch.each do |item|
          #@result_queue.offer({ 'type': "success", 'cat': "Select", 'item': { "guid": item.getGuid(), "tags": ["#{@properties["metadata_name"]}|Overview|Selected"] } })

          log("Exporting file #{item.getGuid()}.#{item.getCorrectedExtension()}")
          exported_file_path = "#{timestamped_folder}/#{item.getGuid()}.#{item.getCorrectedExtension()}"
          begin
            exporter.exportItem(item, exported_file_path)
          rescue => e
            log "Error exporting item: #{e.message}"
          end

          if File.exist?(exported_file_path)
            log("Export successfully")
            if @properties.key?("srv_folder")
              item_srv_path = "#{@properties["srv_folder"]}/#{timestamp}/#{item.getGuid()}.#{item.getCorrectedExtension()}"
              exported_items[item_srv_path] = { 'guid': item.getGuid(), 'item_srv_path': item_srv_path, 'exported_file_path': exported_file_path }
            else
              exported_items[item.getGuid()] = { 'guid': item.getGuid(), 'exported_file_path': exported_file_path }
            end
          else
            @result_queue.offer({ 'type': "error", 'cat': "Export", 'item': { 'guid': item.getGuid() } })
            log("Failed to export #{item.getGuid}")
            @frame&.increase_progress()
          end

          if @frame&.is_task_cancelled?
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
        @frame&.setLabel3 "Batch #{batch_number} processed in #{format_duration(finish - start)}"
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
    @frame&.setLabel1 " "
    @frame&.setLabel2 " "
    @frame&.setLabel3 " "
    @frame&.setLabel4 " "
    @frame&.instance_variable_set(:@cancel_task, false)
    log("=============================================================")

    log("Analyze is complete, Remaining items in classification queue: #{@result_queue.size+@result_remaining_items}")
    @frame&.setLabel1 "Save classifications on nuix items"
    @frame&.instance_variable_get(:@progressBar).maximum = 0 if @frame
    @frame&.instance_variable_get(:@progressBar).value = 0 if @frame
    @frame&.instance_variable_get(:@progressBar).setIndeterminate(true) if @frame

    # wait for classification is done (@result_queue.size == 0)
    while (@result_queue.size+@result_remaining_items > 0) and not @frame&.is_task_cancelled?
      @frame&.setLabel2 "#{@result_queue.size+@result_remaining_items} items remaining"
      sleep(1)
    end

    if @frame&.is_task_cancelled?
      log("Classification is cancelled")
    end

    # then stop @result_executor
    @result_finished = true
    @result_executor.shutdown
    @result_executor.await_termination(1, java.util.concurrent.TimeUnit::MINUTES)

    log("Classification is done")

    @frame&.instance_variable_get(:@progressBar).setIndeterminate(false) if @frame
    
    finalize()

  end

  def upload_batch
    raise "implementation needed"
  end

  def finalize()
    raise "implementation needed"
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

    nuix_item.addTag("#{@properties["metadata_name"]}|Errors|#{error_type}")

    error_msg = "Failed to process the item"
    unless item_data[:response].nil?
      error_msg = "#{error_msg}, Status: #{item_data[:response].code}, Body: #{item_data[:response].body}"
    end
    nuix_item.getCustomMetadata["#{@properties["metadata_name"]}|Error|#{error_type}"] = error_msg
  end

  def log(message)
    @logger.info("#{message}")
    @frame&.log(message)
  end

  def get_logger
    @logger
  end

  def get_exporter
    @utilities.getBinaryExporter
  end
  
  def set_frame(frame)
    @frame = frame
  end

end
