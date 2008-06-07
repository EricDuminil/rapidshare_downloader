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
      
      agent = WWW::Mechanize.new
      page = agent.get(download_url)
      
      form=page.forms.first
      free_or_premium_button=form.buttons.find{|b| b.value==DownloadType}
      page = agent.submit(form, free_or_premium_button)
      
      premium_login_form=page.forms.last
      premium_login_form.accountid=Login
      premium_login_form.password=Password
      page = agent.submit(premium_login_form)
      
      download_form=page.forms.last
      download_button=download_form.buttons.first
      page = agent.submit(download_form, download_button)
      
      available_download_links=page.links.text(DownloadServer)
      one_download_link=available_download_links.pick_one
      one_download_link.text=~DownloadServer
      server_name=$1
      
      puts "Downloading #{filename} from #{server_name}"
      start=Time.now    
      cookie=agent.cookies.first.to_s.sub(/=/,"\t")
      
      open("cookies.txt","w") {|f| f.write(".rapidshare.com\tTRUE\t/\tFALSE\t1731510000\t#{cookie}\n")}
      
      #file_to_dl=agent.get_file one_download_link.href
      system("wget -q --load-cookie cookies.txt -O #{target} #{one_download_link.href}")
      #      open(target, "wb") {|file|
      #        file.write(file_to_dl)
      #      }
      puts "Download finished : #{filename} (in #{Time.now-start} s.)"
    end
  rescue => e
    puts "been here"
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