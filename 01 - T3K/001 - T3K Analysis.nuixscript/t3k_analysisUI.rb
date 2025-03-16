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

require_relative "../../libs.nuixscript/ThirdPartyConnectorUI.rb"
require_relative "../libs.nuixscript/t3k_settings_dialog.rb"

class T3KAnalysisFrame < ThirdPartyConnectorUI

  def additionalComponents
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
    dialog = T3KSettingsDialog.new self, @settings_file
    dialog.setVisible true
  end

  def getTitle
    "T3K CORE classification"
  end

  def storeNalvis?
    @chkbx_nalvis.isSelected
  end
end