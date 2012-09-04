#!/usr/bin/ruby

require 'net/https'
require 'JSON'

user     = '...'
email    = '...'
password = '...'


login_path = "/nsl/services/user/login?app=b31990e7-8583-4251-808f-9dc67b40f5d2&format=json&contentType=plaintext"
data_path = "http://nikeplus.nike.com/plus/activity/running/#{user}/lifetime/activities?indexStart=0&indexEnd=99999"
post_data = "email=#{email}&password=#{password}"
headers = {"Content-Type" => "application/x-www-form-urlencoded"}

#login
url = URI("https://secure-nikeplus.nike.com")
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
resp, data = http.post(login_path, post_data, headers)

unless JSON.parse(resp.body)['serviceResponse']['header']['success'] == 'true'
  puts "Could not login. Server returned error(s):"
  puts "\t" + JSON.parse(resp.body)['serviceResponse']['header']['errorCodes'].collect{|e| e['message']}.join("\n\t")
  exit
end

all_cookies = resp.get_fields('set-cookie')
cookies = all_cookies.collect{|c| c.split('; ')[0]}.join('; ') #make sure we set multiple cookies

#request data
url = URI(data_path)
http = Net::HTTP.new(url.host, url.port)

resp, data = http.get(data_path, {'Cookie' => cookies})

puts JSON.parse(resp.body)
