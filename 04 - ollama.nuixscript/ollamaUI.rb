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

require_relative "../libs.nuixscript/ThirdPartyConnectorUI.rb"
require_relative "ollama_settings_dialog.rb"

class OllamaFrame < ThirdPartyConnectorUI
  def showSettings
    dialog = OllamaSettingsDialog.new self, @settings_file
    dialog.setVisible true
  end

  def getTitle
    "ollama text summary"
  end
end