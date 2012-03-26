StartTime=Time.now

require 'download_helper'
require 'load_configuration'


download_list=File.read(InputFile).gsub(/https?:\/\/\w*\.*rapidshare.com\/#!download\|.*?\|(\d+)\|(.*?)\|\d+\|.*/,'https://rapidshare.com/files/\1/\2').scan(RapidShareURL)

downloads_number=download_list.size

dl=Download.new(download_list, MaxSimDownloads)
dl.launch!


puts "#{downloads_number} downloads in #{(Time.now-StartTime)/60} minutes"
