%w{open-uri fileutils thread yaml net/http net/https}.each{|lib| require lib}

class RapidshareError < RuntimeError ;end

class Download
  def initialize(download_list, simultaneous_downloads)
    @download_list=download_list
    @simultaneous_downloads=simultaneous_downloads
  end
  
  def launch!
    threads=(1..@simultaneous_downloads).collect{
      Thread.new {
        launch_new_download_chain(@download_list)
      }
    }
    threads.each { |aThread|  aThread.join }
  end
  
  protected

  def response_parameters(response)
    Hash[*response.split("\n").map{|line| line.split("=")}.flatten]
  end

  def download_content(url)
    puts "\t->Getting #{url}"
    open(url){|src| src.read}
  end

  #NOTE: Needed?
  def get_cookie
    account_details=call_rapidshare_api('getaccountdetails_v1',credentials.merge(:withcookie=>1),'https')
    response_parameters(account_details)["cookie"]
  end

  def credentials
    {:login=> Login, :password => Password}
  end

  def check_filestatus(file_id, filename)
    file_status=call_rapidshare_api('checkfiles_v1', {:files => file_id, :filenames => filename})
    fid, fname, size, server_id, status, short_host = file_status.split(',')
    case status
      when '0' then raise RapidshareError, "File Not Found"
      when '1' then "https://rs#{server_id}#{short_host}.rapidshare.com/files/#{fid}/#{fname}"
      when '3' then raise RapidshareError, "Server Down"
      when '4' then raise RapidshareError, "File Marked As Illegal"
      when '5' then raise RapidshareError, "Anonymous File Locked"
      else raise 'NotImplemented : TrafficShare'
    end
  end

  def servername(file_id, filename)
    call_rapidshare_api('download_v1', {:fileid => file_id, :filename => filename, :try => 1}.merge(credentials)).split(',').first.split(':').last
  end

  def download_url(file_id, filename,http='https')
    check_filestatus(file_id, filename)
    svr_name=servername(file_id, filename)
    puts "Downloading #{filename} from #{svr_name}"
    url="#{http}://#{svr_name}/cgi-bin/rsapi.cgi"+url_params('download_v1',{:fileid => file_id, :filename => filename}.merge(credentials))
  end

  #NOTE: Needed?
  def cookie
    @@cookie||=get_cookie
  end

  def call_rapidshare_api(action, params, http='https', server='api.rapidshare.com')
    url="#{http}://#{server}/cgi-bin/rsapi.cgi"+url_params(action,params)
    response = download_content(url)
    if response =~ /^ERROR: (.*)/
      raise "RapidshareError : #{$1}"
    else
      response
    end
  end

  def url_params(action,params)
    '?'+{:sub=>action}.merge(params).map{|v,k| "#{v}=#{k}"}.join("&")
  end

  def launch_new_download_chain(dl_list)
    return if dl_list.empty?
    rapidshare_url, file_id, filename=dl_list.shift
    target=File.join(DownloadDir,filename)
    if File.exist?(target) then
      puts "File : #{target} already existing"
    else
      puts "Trying : #{filename}"
      start=Time.now
      system("wget -q -O #{target} --read-timeout=5 \"#{download_url(file_id, filename)}\"")
      puts "Download finished : #{filename} (in #{Time.now-start} s.)"
    end
  rescue => e
    puts "Some problem"
    puts e.inspect
    raise e
    @should_stop=!KeepDownloading
  ensure
    launch_new_download_chain(dl_list) unless @should_stop or dl_list.empty?
  end
end

class Array
  def pick_one
    self[rand(length)]
  end
end
