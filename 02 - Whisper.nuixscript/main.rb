require_relative "whisper.rb"
require_relative "whisperUI.rb"

script_directory = File.dirname(__FILE__)
SETTINGS_FILE = File.join(script_directory, ".", "data.properties")

begin
  if !File.exists? SETTINGS_FILE
    dialog = SettingsDialog.new nil, SETTINGS_FILE
    dialog.setVisible true
  end

  connector = WhisperConnector.new current_case, current_selected_items, utilities, SETTINGS_FILE
  analysis_frame = WhisperFrame.new window, SETTINGS_FILE
  analysis_frame.set_connector(connector)
  connector.set_frame(analysis_frame)
  analysis_frame.setVisible true

rescue StandardError => e
  JOptionPane.showMessageDialog(nil, "An error occurred: #{e.message}")
end

return 0