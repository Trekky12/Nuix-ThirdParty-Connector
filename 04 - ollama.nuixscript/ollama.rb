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
require_relative "../libs.nuixscript/metadata_profile_writer.rb"

class OllamaConnector < ThirdPartyConnector
  def initialize(current_case, current_selected_items, utilities, settings_file)
    super current_case, current_selected_items, utilities, settings_file
    @metadata_fields = {}
  end

  def get_api_url()
    "http://#{@properties["api_host"]}:#{@properties["api_port"]}/api/generate"
  end

  def get_exporter
    @utilities.getTextExporter
  end

  def upload_batch(batch, exported_items)
    log("Uploading batch...")
    
    upload_queue = LinkedBlockingQueue.new
    
    exported_items.each do |item_srv_path, data|
      upload_queue.offer(data)      
    end

    num_threads = java.lang.Runtime.getRuntime.available_processors
    upload_executor = Executors.new_fixed_thread_pool(num_threads)
    
    mutex = Mutex.new
    remaining_items = 0
    upload_finished = false

    runnable = java.lang.Runnable.impl do
      loop do
        begin
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

              # TODO: split the items text into chunks to not lose context on too many tokens
              document_content = File.read(data[:exported_file_path])

              payload = {:prompt => @properties["prompt"].gsub("{document}", document_content), :model => @properties["model"], :format =>"json", :stream => false}

              upload_response = send_rest_request("post", get_api_url(), payload)
        
              if upload_response.nil? || upload_response.code.to_i != 200
                log "Upload failed for batch, Status Code: #{upload_response.code unless upload_response.nil?}"
                delete_file(data[:exported_file_path])
                @result_queue.offer({ 'type': "error", 'cat': "Upload", 'item': { 'guid': data[:guid], 'response': upload_response } })
                
              else
                begin
                  response = JSON.parse(upload_response.body)
                rescue JSON::ParserError => e
                  log "Error parsing upload response: #{e.message}"
                  response = {}
                end
                
                if response.key?("response") and response["response"].length != 0
                  begin
                    result = JSON.parse(response["response"])
                  rescue JSON::ParserError => e
                    log "Error parsing upload result: #{e.message}"
                    result = {}
                  end
                  custom_metadata = {}

                  result.each do | key, value |

                    metadatafield = "#{@properties["metadata_name"]}#{key}"

                    custom_metadata[metadatafield] = value

                    # append as metadata column for metadataprofile
                    if !@metadata_fields.key?(metadatafield)
                      @metadata_fields[metadatafield] = key
                    end
                  end

                  @result_queue.offer({ 'type': "success", 'cat': "Result", 'item': { 'guid': data[:guid], 'tags': ["#{@properties["metadata_name"]}|Overview|classified"], 'custom_metadata': custom_metadata } })

                else
                  @result_queue.offer({ 'type': "error", 'cat': "Result", 'item': { 'guid': data[:guid], 'response': upload_response } })
                end
              end

            rescue StandardError => e
              log("Upload error: #{e.message}")
              log(data)
            end

            delete_file(data[:exported_file_path])
            
            mutex.synchronize do
              remaining_items -= 1
              @frame&.increase_progress()
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
    while (upload_queue.size > 0 or remaining_items > 0) and not @frame&.is_task_cancelled?
      log "#{upload_queue.size} items remaining to upload"
      log "#{remaining_items} items remaining to receive the results"
      sleep(1)
    end
    upload_finished = true
    upload_executor.shutdown    
    upload_executor.await_termination(1, java.util.concurrent.TimeUnit::MINUTES)
    
    log "Upload finished"
    
    return true
  end
  
  def finalize()

    # Write Metadataprofile
    log("Found metadata fields")
    log(@metadata_fields)
    mdp_utility = MetadataProfileReaderWriter.new @current_case
    mdp_utility.writeProfile("Ollama Result", @properties["metadata_name"], @metadata_fields)

    # Open metadataprofile
    metadatastore = @current_case.getMetadataProfileStore()
    metadataprofile = metadatastore.getMetadataProfile("Ollama Result")
    if metadataprofile
      # @window.closeAllTabs
      source_guids = @current_selected_items.map { |item| item.guid }.compact
      guid_search = "guid:(#{source_guids.join " OR "})"
      @frame&.instance_variable_get(:@window).openTab "workbench", { "search" => guid_search, "metadataProfile" => metadataprofile } if @frame
    end
  end
end
