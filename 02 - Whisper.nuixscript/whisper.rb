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

require_relative "../libs.nuixscript/ThirdPartyConnector.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, ".", "data.properties")

class WhisperFrame < ThirdPartyConnector
  def initialize(window, current_case, current_selected_items, utilities)
    super window, current_case, current_selected_items, utilities

    setTitle "Whisper transcription"
  end

  def get_api_url()
    "http://#{@api_host}:#{@api_port}/asr?output=json"
  end

  def upload_batch(batch, exported_items)
    # Uploading files in batch mode
    log("Uploading batch...")
    
    upload_queue = LinkedBlockingQueue.new
    
    exported_items.each do |item_srv_path, data|
      
      form_data = [['audio_file', File.open(data[:exported_file_path])]]
      
      upload_queue.offer({:data => data, :form => form_data})      
    end
    
    num_threads = java.lang.Runtime.getRuntime.available_processors
    upload_executor = Executors.new_fixed_thread_pool(num_threads)
    
    mutex = Mutex.new
    remaining_items = 0
    upload_finished = false

    runnable = java.lang.Runnable.impl do
      loop do
        begin
          
          # break loop
          # synchronize access to the shutdown state
          # break can't be in the mutex
          shutdown = false
          
          mutex.synchronize do
            if upload_finished and upload_queue.size == 0
              shutdown = true
            end
          end
          
          break if shutdown
        
          data = upload_queue.poll
          if data
            mutex.synchronize do
              remaining_items += 1
            end
            
            begin
              upload_response = send_rest_request("post", get_api_url(), data[:form], "multipart/form-data")
        
              if upload_response.nil? || upload_response.code.to_i != 200
                log "Upload failed for batch, Status Code: #{upload_response.code unless upload_response.nil?}"

                # Clean up the exported item
                delete_file(data[:data][:exported_file_path])

                # Track item as export failed
                @result_queue.offer({ 'type': "error", 'cat': "Upload", 'item': { 'guid': data[:data][:guid], 'response': upload_response } })
                
              else
                begin
                  response = JSON.parse(upload_response.body)
                rescue JSON::ParserError => e
                  log "Error parsing upload response: #{e.message}"
                  response = {}
                end
                
                if response.key?("text") and response["text"].length != 0
                  #@result_queue.offer({ 'type': "success", 'cat': "Result", 'item': { 'guid': data[:data][:guid], 'tags': ["#{@custom_metadata_field_name}|Overview|transcripted"], 'custom_metadata': {}, 'text': response["text"] } })
                  @result_queue.offer({ 'type': "success", 'cat': "Result", 'item': { 'guid': data[:data][:guid], 'tags': ["#{@custom_metadata_field_name}|Overview|transcripted"], 'custom_metadata': {"#{@custom_metadata_field_name}|Transcription": response["text"]} } })
                else
                  @result_queue.offer({ 'type': "error", 'cat': "Result", 'item': { 'guid': data[:data][:guid], 'response': upload_response } })
                end
              end
              
            rescue StandardError => e
              log("Upload error: #{e.message}")
              log(data)
            end

            # Clean up the exported item
            delete_file(data[:data][:exported_file_path])
            
            mutex.synchronize do
              remaining_items -= 1
              increase_progress()
            end
          end
        rescue StandardError => e
          log("An error occurred with the upload loop: #{e.message}")
        end
      end
    end

    num_threads.times do 
      upload_executor.submit(runnable)
    end
    
    # wait for results
    while (upload_queue.size > 0 or remaining_items > 0) and not @cancel_task
      log "#{upload_queue.size} items remaining to upload"
      log "#{remaining_items} items remaining to receive the results"
      #setLabel3 "#{upload_queue.size+remaining_items} items remaining"
      sleep(1)
    end
    # then stop executor
    upload_finished = true
    upload_executor.shutdown    
    upload_executor.await_termination(1, java.util.concurrent.TimeUnit::MINUTES)
    
    log "Upload finished"
    
    return true
  end
  
  def finalize(items)
  
    source_guids = items.map { |item| item.guid }.compact
    guid_search = "guid:(#{source_guids.join " OR "})"
  
    log "Save transcription as text"
    items = @current_case.searchUnsorted("(#{guid_search}) AND (custom-metadata:\"#{@custom_metadata_field_name}|Transcription\":*)")
    log "#{items.size} Items transcripted"
      
    setProgressBarMax 0
    setProgressBarValue 0
    @progressBar.setIndeterminate(true)
  
    # Storing text in parallel is not working so this is done at last:
    # Search for items with custom-metadata and store as text
    @current_case.withWriteAccess do      
      items.each_with_index do |nuix_item, index|
        log "Store text on item #{index+1}/#{items.size} with guid #{nuix_item.getGuid}"
        setLabel2 "#{items.size-index} items remaining"
        nuix_item.modify do | item_modifier |
          data = nuix_item.getCustomMetadata["#{@custom_metadata_field_name}|Transcription"]
          item_modifier.replaceText("============= TRANSCRIPTION =============\n\n#{data}")
        end
      end
    end
    
    @progressBar.setIndeterminate(false)
  
    # @window.closeAllTabs
    @window.openTab "workbench", { "search" => guid_search }
  end
end

begin
  if !File.exists? SETTINGS_FILE
    dialog = SettingsDialog.new nil, SETTINGS_FILE
    dialog.setVisible true
  end
  analysis_frame = WhisperFrame.new window, current_case, current_selected_items, utilities
  analysis_frame.setVisible true
rescue StandardError => e
  JOptionPane.showMessageDialog(nil, "An error occurred: #{e.message}")
end

return 0