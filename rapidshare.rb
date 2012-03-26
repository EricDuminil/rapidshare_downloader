StartTime=Time.now

require File.expand_path("download_helper",File.dirname(__FILE__))
require File.expand_path("load_configuration",File.dirname(__FILE__))


download_list=File.read(InputFile).gsub(/https?:\/\/\w*\.*rapidshare.com\/#!download\|.*?\|(\d+)\|(.*?)\|\d+\|.*/,'https://rapidshare.com/files/\1/\2').scan(RapidShareURL)

downloads_number=download_list.size

dl=Download.new(download_list, MaxSimDownloads)
dl.launch!


puts "#{downloads_number} downloads in #{(Time.now-StartTime)/60} minutes"
