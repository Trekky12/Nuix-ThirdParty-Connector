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

class MetadataProfileReaderWriter
  def initialize(current_case)
    @current_case = current_case
  end

  def getMetadataProfilePath(profile_name)
    return @current_case.getLocation().getAbsolutePath() + File::SEPARATOR +
             "Stores" + File::SEPARATOR + "User Data" + File::SEPARATOR +
             "Metadata Profiles" + File::SEPARATOR + profile_name + ".profile"
  end

  def writeProfile(profile_name, custom_metadata_field_name, data)
    metadataProfilePath = getMetadataProfilePath(profile_name)

    metadataProfileContent = ""

    if File.exist?(metadataProfilePath)
      metadataProfileContent = File.read(metadataProfilePath)
    else
      metadataProfileContent << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      metadataProfileContent << "<metadata-profile xmlns=\"http://nuix.com/fbi/metadata-profile\">\n"
      metadataProfileContent << "  <metadata-list>\n"

      metadataProfileContent << "    <metadata type=\"SPECIAL\" name=\"Name\" />\n"
      metadataProfileContent << "    <metadata type=\"SPECIAL\" name=\"Path Name\" />\n"
      metadataProfileContent << "    <metadata type=\"DERIVED\" name=\"#Treffer\">\n"
      metadataProfileContent << "      <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Count\" />\n"
      metadataProfileContent << "    </metadata>\n"
      metadataProfileContent << "    <metadata type=\"DERIVED\" name=\"Treffer\">\n"
      metadataProfileContent << "      <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Detections\" />\n"
      metadataProfileContent << "    </metadata>\n"
      metadataProfileContent << "    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Error|Export\" />\n"
      metadataProfileContent << "    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Error|Upload\" />\n"
      metadataProfileContent << "    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Error|PollQuery\" />\n"
      metadataProfileContent << "    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Error|ResultQuery\" />\n"
      metadataProfileContent << "    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|Error|Result\" />\n"

      metadataProfileContent << "  </metadata-list>\n"
      metadataProfileContent << "</metadata-profile>"
    end

    # Filter out additional metadata items that are already present
    existing_metadata_names = metadataProfileContent.scan(/<metadata type="DERIVED" name="([^"]+)">/).flatten
    filtered_metadata = data.reject do |tag, name|
      existing_metadata_names.include?(name)
    end

    classificationsMetadata = ""
    filtered_metadata.each do |tag, name|
      classificationsMetadata << "    <metadata type=\"DERIVED\" name=\"#{name}\">\n"
      classificationsMetadata << "      <metadata type=\"CUSTOM\" name=\"#{tag}\" />\n"
      classificationsMetadata << "    </metadata>\n"
    end

    insert_position = metadataProfileContent.index("    <metadata type=\"CUSTOM\" name=\"#{custom_metadata_field_name}|RAW|Metadata\" />")
    if insert_position
      metadataProfileContent = metadataProfileContent.insert(insert_position, classificationsMetadata)
    end

    puts(metadataProfileContent)

    File.write(metadataProfilePath, metadataProfileContent)
  end
end
