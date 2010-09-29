dl_options_file  = ['download_options.yml', 'download_options.yml.template'].find{|f| File.exist?(f)}
DL_options       = YAML.load_file(dl_options_file)
Login,Password   = DL_options['login'] || "anonymous", DL_options['password']||""
DownloadDir      = DL_options['download_dir'] || "download/"
MaxSimDownloads  = DL_options['max_simultaneous_downloads']  || 3
InputFile        = DL_options['download_list_file'] || 'to_download.txt'
KeepDownloading  = DL_options['keep_downloading']=~/(true|yes)/


FileUtils.mkpath DownloadDir
DownloadType    = Password.empty? ? /Free/ : /Premium/

RapidShareURL=/(?:href=")?(http:\/\/rapidshare\.com\/files\/(\d{1,10})\/([^\s"]+))(")?/
DownloadServer=/Download via (.*)/
