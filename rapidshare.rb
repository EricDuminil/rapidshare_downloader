StartTime=Time.now

require 'download_helper'
require 'load_configuration'


download_list=File.read(InputFile).grep(RapidShareURL){[$1,$2]}
downloads_number=download_list.size

dl=Download.new(download_list, MaxSimDownloads)
dl.launch!


puts "#{downloads_number} downloads in #{(Time.now-StartTime)/60} minutes"