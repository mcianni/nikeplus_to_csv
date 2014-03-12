#!/usr/bin/ruby

require 'net/https'
require 'JSON'
require 'csv'

user     = '...'
email    = '...'
password = '...'

module Enumerable
  def flatten_with_path(parent_prefix = nil)
    res = {}

    self.each_with_index do |elem, i|
      if elem.is_a?(Array)
        k, v = elem
      else
        k, v = i, elem
      end
      key = parent_prefix ? "#{parent_prefix}.#{k}" : k # assign key name for result hash
      if v.is_a? Enumerable
        res.merge!(v.flatten_with_path(key)) # recursive call to flatten child elements
      else
        res[key] = v
      end
    end

    res
  end
end

login_path = "/nsl/services/user/login?app=\
b31990e7-8583-4251-808f-9dc67b40f5d2&format=json&contentType=plaintext"
data_path = "http://nikeplus.nike.com/plus/activity/running/#{user}/lifetime/activities?indexStart=0&indexEnd=9999"
post_data = "email=#{email}&password=#{password}"
headers = {"Content-Type" => "application/x-www-form-urlencoded"}

#login
url = URI("https://secure-nikeplus.nike.com")
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
resp, data = http.post(login_path, post_data, headers)

unless JSON.parse(resp.body)['serviceResponse']['header']['success'] == 'true'
  puts "Could not login. Server returned the following error(s):"
  puts "\t" + JSON.parse(resp.body)['serviceResponse']['header']['errorCodes'].collect{|e| e['message']}.join("\n\t")
  exit
end

all_cookies = resp.get_fields('set-cookie')
cookies = all_cookies.collect{|c| c.split('; ')[0]}.join('; ') #make sure we set multiple cookies

#request data
url = URI(data_path)
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

resp, data = http.get(data_path, {'Cookie' => cookies})

data = JSON.parse(resp.body)

# The data for each activity may vary in order. We grab all keys here and we'll use
# that as the standard order for outputing to CSV
flattened_activities = data['activities'].map{ |activity| activity.flatten_with_path }
keys = flattened_activities.map(&:keys).flatten.uniq

CSV.open("out.csv", "w", { :headers => keys, :write_headers => true }) do |csv|
  flattened_activities.each do |activity|
    csv << keys.map{ |key| activity[key] }
  end
end
