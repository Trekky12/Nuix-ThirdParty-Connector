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

require_relative "../../libs.nuixscript/ThirdPartyConnector.rb"
require_relative "../libs.nuixscript/metadata_profile_writer.rb"
require_relative "../libs.nuixscript/t3k_settings_dialog.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, "..", "data.properties")

class T3KAnalysisFrame < ThirdPartyConnector
  def initialize(window, current_case, current_selected_items, utilities)
    super window, current_case, current_selected_items, utilities

    setTitle "T3K CORE classification"
    @metadata_fields = {}

    gbc_chkbx_nalvis = java.awt.GridBagConstraints.new
    gbc_chkbx_nalvis.gridx = 0
    gbc_chkbx_nalvis.gridy = 2
    gbc_chkbx_nalvis.anchor = java.awt.GridBagConstraints::NORTHWEST
    gbc_chkbx_nalvis.insets = java.awt.Insets.new(5, 10, 5, 10)
    @chkbx_nalvis = JCheckBox.new("Store NaLViS Encodings")
    @chkbx_nalvis.setSelected(true)
    @chkbx_nalvis.setEnabled(true)
    @panel.add(@chkbx_nalvis, gbc_chkbx_nalvis)

    @items_to_disable.append(@chkbx_nalvis)

    pack
  end

  def showSettings
    dialog = T3KSettingsDialog.new self, SETTINGS_FILE
    dialog.setVisible true
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

  def upload_batch(batch, exported_items)
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
        @result_queue.offer({ 'type': "error", 'cat': "Upload", 'item': { 'guid': item.getGuid(), 'response': upload_response } })
      end

      return false
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
        #if not item_result_extracted
        #  sleep(0.01)
        #end
      end
      log "Waiting for next batch check"
      sleep(1)
    end

    return true
  end

  def getItemResult(item_srv_path, item_data)
    upload_id = item_data[:upload_id]
    log("Item #{upload_id}: Polling")
    poll_response = send_rest_request("get", "#{get_poll_url()}/#{upload_id}")

    if poll_response.nil? || poll_response.code.to_i != 200
      log "Item #{upload_id}: Polling failed for item: #{item_data[:guid]}, Status Code: #{poll_response.code unless poll_response.nil?}"
      @result_queue.offer({ 'type': "error", 'cat': "PollQuery", 'item': { 'guid': item_data[:guid], 'response': poll_response } })
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
          @result_queue.offer({ 'type': "error", 'cat': "ResultQuery", 'item': { 'guid': item_data[:guid], 'response': result_response } })
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
          @result_queue.offer({ 'type': "error", 'cat': "Result", 'item': { 'guid': item_data[:guid], 'response': result_response } })
        end

        delete_file(item_data[:exported_file_path])
        increase_progress()
        return true # Mark the item as finished
      end
    end
  end

  def parseResult(result_data, nuix_item_guid)
    result = { 'type': "success", 'cat': "Result", 'item': { "guid": nuix_item_guid, "tags": [], "custom_metadata": {} } }

    metadata = result_data["metadata"]
    result[:item][:custom_metadata]["#{@custom_metadata_field_name}|RAW|Metadata"] = metadata.to_json

    detections = result_data["detections"]

    detection_count = 0
    all_detections = []
    all_detections_max_score = {}
    all_extractions = []
    detections.each_pair do |detection_idx, detection|
      if detection.size > 0

        #detection.each_pair do |key, value|
        #  result[:item][:custom_metadata]["#{@custom_metadata_field_name}|RAW|AllResults|#{detection_idx}|#{key}"] = value.to_s
        #end

        info = nil
        type = nil
        score = nil
        description = nil
        text = nil
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
        when "OCR hit"
          #log "OCR match detected"
          info = "OCR #{detection["info"]}"
          type = "OCR"
          description = detection["description"]
        when "transcription hit"
          #log "Transcription match detected"
          info = "Transcription #{detection["info"]}"
          type = "Transcription"
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
        when "OCR text"
          #log "OCR extraction"
          info = "#{detection["info"]}"
          type = "OCR extraction"
          text = detection["text"]
        when "transcription text"
          log "transcription extraction"
          info = "#{detection["info"]}"
          type = "Transcription extraction"
          text = detection["segments"].map do |segment|
            "#{segment["start_string"]}: #{segment["text"]}"
          end.join("\n")
        else
          #log "Unknown type detected"
          info = "Unknown"
          type = "Unknown"
          description = "Unknown"
        end

        if text
          result[:item][:tags] << "#{@custom_metadata_field_name}|Overview|Something extracted"
          result[:item][:tags] << "#{@custom_metadata_field_name}|Results|#{type}|#{info}"

          result[:item][:custom_metadata]["#{@custom_metadata_field_name}|Extractions|#{type}|#{all_extractions.size}|text"] = text
          result[:item][:custom_metadata]["#{@custom_metadata_field_name}|Extractions|#{type}|#{all_extractions.size}|info"] = info
          all_extractions.append("#{text}")

          # Skip remaining part
          next
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
            result[:item][:tags] << "#{@custom_metadata_field_name}|Scores|#{selected_range[:tag]}|#{score}%"

            # store info as tag
            result[:item][:tags] << "#{@custom_metadata_field_name}|Results|#{type}|#{selected_range[:tag]}|#{score}%"
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
          result[:item][:tags] << "#{@custom_metadata_field_name}|Results|#{type}|#{description}"

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
          result[:item][:tags] << "#{@custom_metadata_field_name}|Error|DetectionError"
        else
          # log "Something detected"
          result[:item][:tags] << "#{@custom_metadata_field_name}|Overview|Something detected"
          detection_count += 1
        end
      else
        #log "Nothing detected"
        result[:item][:tags] << "#{@custom_metadata_field_name}|Overview|Nothing detected"
      end
    end

    # store max score for this type of detection
    all_detections_max_score.each_pair do |info, score|
      metadatafield = "#{@custom_metadata_field_name}|Result|#{info}"

      result[:item][:custom_metadata][metadatafield] = score

      # append as metadata column for metadataprofile
      if !@metadata_fields.key?(metadatafield)
        @metadata_fields[metadatafield] = info
      end
    end

    # Set custom metadata on the item
    # store all types of detections in one field
    result[:item][:custom_metadata]["#{@custom_metadata_field_name}|Detections"] = all_detections.join("\n")
    result[:item][:custom_metadata]["#{@custom_metadata_field_name}|Count"] = detection_count
    result[:item][:custom_metadata]["#{@custom_metadata_field_name}|RAW|Detections"] = detections.to_json

    # NaLViS encodings
    if @chkbx_nalvis.isSelected && result_data.has_key?("nalvis_result")
      nalvis_result = result_data["nalvis_result"]
      result[:item][:custom_metadata]["#{@custom_metadata_field_name}|nalvis"] = nalvis_result.to_json
    end

    @result_queue.offer(result)
  end

  def finalize(items)

    # Write Metadataprofile
    log("Found metadata fields")
    log(@metadata_fields)
    mdp_utility = MetadataProfileReaderWriter.new @current_case
    mdp_utility.writeProfile("T3K Result", @custom_metadata_field_name, @metadata_fields)

    # Open metadataprofile
    metadatastore = @current_case.getMetadataProfileStore()
    metadataprofile = metadatastore.getMetadataProfile("T3K Result")
    if metadataprofile
      # @window.closeAllTabs
      source_guids = items.map { |item| item.guid }.compact
      guid_search = "guid:(#{source_guids.join " OR "})"
      @window.openTab "workbench", { "search" => guid_search, "metadataProfile" => metadataprofile }
    end
  end
end

begin
  if !File.exists? SETTINGS_FILE
    dialog = T3KSettingsDialog.new nil, SETTINGS_FILE
    dialog.setVisible true
  end
  analysis_frame = T3KAnalysisFrame.new window, current_case, current_selected_items, utilities
  analysis_frame.setVisible true
rescue StandardError => e
  JOptionPane.showMessageDialog(nil, "An error occurred: #{e.message}")
end

return 0
