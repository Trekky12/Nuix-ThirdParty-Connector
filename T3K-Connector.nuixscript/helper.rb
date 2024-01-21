# This file is part of Nuix-T3K-Connector (https://github.com/trekky12/nuix-t3k-connector).
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

def format_duration(seconds)
  minutes = seconds / 60
  remaining_seconds = seconds % 60
  return "#{minutes.to_i} min. #{remaining_seconds.round(3)} sec."
end

def send_rest_request(http_method, url, payload = nil)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  http.read_timeout = REST_API_TIMEOUT
  request = Net::HTTP.const_get(http_method.capitalize).new(uri.request_uri)

  response = nil

  if payload
      request.add_field("Content-Type", "application/json; utf-8")
      request.body = payload.to_json
  end

  begin
      response = http.request(request)
  rescue StandardError => e
      log("Error with HTTP Request #{e.message}")
  ensure
      http.finish if http.started?
  end

  return response
end