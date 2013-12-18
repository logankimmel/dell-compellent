require 'puppet/provider/compellent'
require 'puppet/lib/ResponseParser'

Puppet::Type.type(:compellent_map_volume).provide(:compellent_map_volume, :parent => Puppet::Provider::Compellent) do
  @doc = "Manage Compellent map/unmap volume."

  def showvolume_commandline
    command = "volume show -name '#{@resource[:name]}'"
    folder_value = @resource[:folder] 
    
    if folder_value.length  > 0
      command = command + " -folder '#{folder_value}'"
    end
    return command
  end

   def showserver_commandline
    command = "server show -name '#{@resource[:servername]}'"
    folder_value = #{@resource[:folder]} 
    if "#{folder_value}".size != 0
      command = command + " -folder '#{folder_value}'"
    end
    return command
  end

  def get_log_path(num)
    temp_path = Pathname.new(__FILE__).parent
    Puppet.debug("Temp PATH - #{temp_path}")
    $i = 0
    $num = num
    path = Pathname.new(temp_path)
    while $i < $num  do
      path = Pathname.new(temp_path)
      temp_path = path.dirname
      $i +=1
    end
    temp_path = temp_path.join('logs')
    Puppet.debug("Log Path #{temp_path}")
    return  temp_path
  end
  
  def get_unique_refid()
    randno = Random.rand(100000)
    pid = Process.pid
    return "#{randno}_PID_#{pid}"
  end
  
  def get_deviceid
    Puppet.debug("Fetching information about the Volume")
    resourcename = @resource[:name]
    Puppet.debug("executing show volume command")

    vol_show_cli = showvolume_commandline
    volumeshow_exitcodexml = "#{get_log_path(2)}/volumeShowExitCode_#{get_unique_refid}.xml"
    volumeshow_responsexml = "#{get_log_path(2)}/volumeShowResponse_#{get_unique_refid}.xml"
		
    volume_show_command = "java -jar /etc/puppetlabs/puppet/modules/compellent/lib/puppet/util/network_device/compellent/CompCU-6.3.jar -host #{@resource[:host]} -user #{@resource[:user]} -password #{@resource[:password]} -xmloutputfile #{volumeshow_exitcodexml} -c \"#{vol_show_cli} -xml #{volumeshow_responsexml}\""
    system(volume_show_command)
    Puppet.debug("in method get_deviceid, after exectuing show volume command")
 

    file1_path = "/tmp/volshow_#{resourcename}_exitcode.xml"
    file2_path = "/tmp/volshow_#{resourcename}_response.xml"
    parser_obj=ResponseParser.new('_')
    parser_obj.parse_discovery(file1_path,file2_path,0)
    hash= parser_obj.return_response 
    device_id = "#{hash['volume_DeviceID']}"

    return device_id
  end

  def map_volume_commandline
    command = "volume map -server '#{@resource[:servername]}'"
    device_id = get_deviceid
    Puppet.debug("Device Id for Volume - #{device_id}")
    
    if  #{device_id} != ""
        Puppet.debug("appending device ID in command")
        command = command + " -deviceid #{device_id}"
    end

    lun_value = @resource[:lun]
    if "#{lun_value}".size != 0
    	command = command + " -lun '#{lun_value}'"
    end
    
    localport_value = @resource[:localport]
    if "#{localport_value}".size != 0
    	command = command + " -localport '#{localport_value}'"
    end

    volume_boot = @resource[:boot]    
    if (volume_boot == :true)
	    command = command + " -boot"
    end
    
    volume_force = @resource[:force]
    if (volume_force == :true)
	    command = command + " -force"
    end
    
    volume_readonly = @resource[:readonly]
    if (volume_readonly == :true)
    	command = command + " -readonly"
    end
  
    volume_singlepath = @resource[:singlepath] 
    if (volume_singlepath == :true)
	    command = command + " -singlepath"
    end

    return command
  end

  def get_path(num)
    temp_path = Pathname.new(__FILE__).parent
    Puppet.debug("Temp PATH - #{temp_path}")
    $i = 0
    $num = num
    path = Pathname.new(temp_path)
    while $i < $num  do
      path = Pathname.new(temp_path)
      temp_path = path.dirname
      $i +=1
    end
    temp_path = temp_path.join('lib/CompCU-6.3.jar')
    Puppet.debug("Path #{temp_path}")
    return  temp_path
  end

  def create   
    Puppet.debug("Inside create method.")
    libpath = get_path(2)
    resourcename = @resource[:name]
    map_volume_cli = map_volume_commandline
    Puppet.debug("Map Volume CLI - #{map_volume_cli}")
    Puppet.debug("Map volume with name '#{resourcename}'")
    mapvolume_exitcodexml = "#{get_log_path(2)}/mapVolumeExitCode_#{get_unique_refid}.xml"
		
    map_volume_create_command = "java -jar #{libpath} -host #{@resource[:host]} -user #{@resource[:user]} -password #{@resource[:password]} -xmloutputfile #{mapvolume_exitcodexml} -c \"#{map_volume_cli}\""
    Puppet.debug(map_volume_create_command)

    response =  system (map_volume_create_command)

    parser_obj=ResponseParser.new('_')
    file_path = "/tmp/mapvolume_#{resourcename}_exitcode.xml"
    parser_obj.parse_exitcode(file_path)
    hash= parser_obj.return_response
     if "#{hash['Success']}".to_str() == "TRUE" 
        Puppet.debug("Map Volume command exectued successfully..")
     else
        raise Puppet::Error, "#{hash['Error']}"
     end

  end

  def destroy  
    Puppet.debug("Inside destroy method.")
    libpath = get_path(2)
    resourcename = @resource[:name]
    device_id = get_deviceid
    Puppet.debug("Device Id for Volume - #{device_id}")    
    if  #{device_id} != "" 
        Puppet.debug("Invoking destroy command")
	unmapvolume_exitcodexml = "#{get_log_path(2)}/unmapVolumeExitCode_#{get_unique_refid}.xml"
        unmap_volume_destroy_command = "java -jar #{libpath} -host #{@resource[:host]} -user #{@resource[:user]} -password #{@resource[:password]} -xmloutputfile #{unmapvolume_exitcodexml} -c \"volume unmap -deviceid #{device_id}\""
        Puppet.debug(unmap_volume_destroy_command)
        system(unmap_volume_destroy_command)

	parser_obj=ResponseParser.new('_')
        file_path = "/tmp/unmapvolume_#{resourcename}_exitcode.xml"
        parser_obj.parse_exitcode(file_path)
        hash= parser_obj.return_response
          if "#{hash['Success']}".to_str() == "TRUE" 
           Puppet.debug("UnMap Volume command exectued successfully..")
          else
           raise Puppet::Error, "#{hash['Error']}"
          end
    end 

  end

 def exists?
    
    libpath = get_path(2)
    resourcename = @resource[:name]
    show_server_cli = showserver_commandline
    servershow_exitcodexml = "#{get_log_path(2)}/serverShowExitCode_#{get_unique_refid}.xml"
    servershow_responsexml = "#{get_log_path(2)}/serverShowResponse_#{get_unique_refid}.xml"
	
    show_server_command = "java -jar #{libpath} -host #{@resource[:host]} -user #{@resource[:user]} -password #{@resource[:password]} -xmloutputfile #{servershow_exitcodexml} -c \"#{show_server_cli} -xml #{servershow_responsexml}\""
    system(show_server_command)
    parser_obj=ResponseParser.new('_')
    hash = parser_obj.retrieve_server_properties(servershow_responsexml)
    volume_name = "#{hash['Volume']}"
 
    if volume_name.include? resourcename
        Puppet.debug("Puppet::Volume name exist")
        true
    else
      Puppet.debug("Puppet::Volume name does not exist")
      false
    end

    end

end



