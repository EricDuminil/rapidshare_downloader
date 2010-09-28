%w{rubygems mechanize net/http fileutils thread yaml}.each{|lib| require lib}

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
  
  def launch_new_download_chain(dl_list)
    return if dl_list.empty?
    download_url, filename=dl_list.shift
    
    target=File.join(DownloadDir,filename)
    if File.exist?(target) then
      puts "File : #{target} already existing"
    else
      puts "Trying : #{filename}"
      agent = WWW::Mechanize.new
      page = agent.get(download_url)
      
      form=page.forms.find{|f| f.buttons.first.value=~DownloadType}
      free_or_premium_button=form.buttons.first
      page = agent.submit(form, free_or_premium_button)
      
      premium_login_form=page.forms.last
      premium_login_form.accountid=Login
      premium_login_form.password=Password
      page = agent.submit(premium_login_form)
      
      download_form=page.forms.last
      download_button=download_form.buttons.first
      page = agent.submit(download_form, download_button)
      
      dl=page.forms.find{|f| f.name=="dlf"}
      download_link=dl.action

      #server_name=dl.radiobuttons.find{|rb| rb.checked}
     server_name = download_link
     puts "Link : #{download_link}"
     puts "Downloading #{filename} from #{server_name}"
      start=Time.now
      cookie=agent.cookies.first.to_s.sub(/=/,"\t")
      
      open("cookies.txt","w") {|f| f.write(".rapidshare.com\tTRUE\t/\tFALSE\t1731510000\t#{cookie}\n")}
      sleep(1)
      
      system("wget -q --load-cookie cookies.txt -O #{target} --read-timeout=5 #{download_link}")
      
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
