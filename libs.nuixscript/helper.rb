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

require "net/http"
require "uri"
require "json"

def format_duration(seconds)
  minutes = seconds / 60
  remaining_seconds = seconds % 60
  return "#{minutes.to_i} min. #{remaining_seconds.round(3)} sec."
end

def send_rest_request(http_method, url, payload = nil, content_type = 'application/json; utf-8', timeout = 1800)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  http.read_timeout = timeout
  request = Net::HTTP.const_get(http_method.capitalize).new(uri.request_uri)

  response = nil

  if payload
    request['Content-Type'] = content_type
    if content_type.start_with?('multipart/form-data')
      request.set_form payload, 'multipart/form-data'
    else
      request.body = payload.to_json
    end
  end

  begin
    response = http.request(request)
  rescue StandardError => e
    log("Error with HTTP Request #{e.message}")
  ensure
    http.finish if http.started?
  end
  
  # close opened file
  if payload
	  payload.each do |key, value|
		if value.is_a?(File) && !value.closed?
		  value.close # Close the file after reading
		end
	  end
  end

  return response
end

def read_properties(file)
  properties = {}
  File.open(file, "r") do |file|
    file.each_line do |line|
      key, value = line.strip.split("=")
      properties[key] = value
    end
  end
  properties
end
