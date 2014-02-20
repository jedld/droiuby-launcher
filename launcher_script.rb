java_import "android.content.pm.ActivityInfos"

#ruby script that handles the behavior of the launcher
class Main < Activity

  def before_content_render
    _current_activity.setRequestedOrientation(ActivityInfo::SCREEN_ORIENTATION_LANDSCAPE);
  end

  def on_create
    
      if _P.has_key?(:app_url)
        V('#app_url').text= _P.get(:app_url)
      end
      
      @start_console_btn = V('#start_console')
      @stop_console_btn = V('#stop_console')
      @auto_start_checkbox = V('#auto_start')
      
      @start_console_btn.on(:click) do |view|
        start_web_console  
      end
      
      @stop_console_btn.on(:click) do |view|
        @stop_console_btn.text = "Shutting down console ...."
        $httpd.shutdownConsole()
      end
      
      
      V('#run').on(:click) do |view|
          app_url = V('#app_url')
          
          url_str = app_url.text
          
          unless url_str.match(/^http:\/\//) || url_str.match(/^file:\/\//) || url_str.match(/^https:\/\//)
            url_str = "http://#{url_str}"
          end
          
          #store in prefs to be auto launched next time
          _P.update_attributes!(app_url: url_str)
          
          launch url_str
      end
      
      V('#qrcode').on(:click) do |view|
        integrator = Java::com.droiuby.client.utils.intents.IntentIntegrator.new(me)
        integrator.initiateScan
      end
            
      if _P.get(:auto_start) == 'true'
        @auto_start_checkbox.selected = true
        start_web_console 
      else
        @auto_start_checkbox.selected = false
      end
    
  end
  
  def on_activity_result(request_code, result_code, intent)
    app_url = V('#app_url')
    scanResult = Java::com.droiuby.client.utils.intents.IntentIntegrator.parseActivityResult(request_code, result_code, intent.native)
    if scanResult != nil
      app_url.text= scanResult.getContents()
    end
  end
  
  private
  
  def start_web_console
    
    @start_console_btn.text = "Starting Webconsole ...."
    
    puts "starting console"
    
    Droiuby::Utils.start_web_console do |httpd|
      $httpd = httpd
      
      puts "start web console done"
      @start_console_btn.hide!
      
      @auto_start_checkbox.on(:checked_changed) do |view|
        if view.selected
          _P.update_attributes!(auto_start: 'true')
        else
          _P.update_attributes!(auto_start: 'false')
        end
      end
      
      @stop_console_btn.show!
      
      async.perform {
        Java::com.droiuby.client.core.utils.Utils.getLocalIpAddress(me)
      }.done { |result|
        V('#ip_address_container').show!
        V('#ip_address').text = "#{result}:4000"
      }.start
      
    end  
  end
end
