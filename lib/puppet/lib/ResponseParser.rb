# Utility Class - parsing XML

require 'rexml/document'

include REXML

class ResponseParser

  attr_accessor :response_map,:seperator
  def initialize(seperator)
    @response_map = Hash.new
    @seperator=seperator
  end

  public


  def parse_exitcode(output_file_name)
        @seperator=""
        result_file = File.new(output_file_name)
        output_doc = Document.new(result_file)
        index=1;
        output_doc.root.each_element do |system|
          key= #{system.name()
          read_node(system,key)
          if index > 0 then index+=1 end
        end
      @response_map
   end

  def parse_discovery(result_file_name, output_file_name,index)
    result_file = File.new(result_file_name)
    result_doc = Document.new(result_file)
    result= XPath.first(result_doc, "//Success")
    if result.text.eql?'TRUE'
      result_file = File.new(output_file_name)
      output_doc = Document.new(result_file)
      #index=1;
      output_doc.root.each_element do |system|
        if index > 0 then key= "#{system.name()}#{@seperator}#{index}" else key= "#{system.name()}"
        end
        read_node(system,key)
        if index > 0 then index+=1 end
      end
    end
    @response_map
  end

  def read_node(node,key_name)
    if node.has_elements?
      node.each_element do |child|
        read_node(child,key_name)
      end
    else
      key_name="#{key_name}#{@seperator}#{node.name()}"
      self.response_map[key_name]=node.text
    end
    key_name
  end

  #  def parse_discovery(result_file_name, output_file_name,index)
  #    result_file = File.new(result_file_name)
  #    result_doc = Document.new(result_file)
  #    result= XPath.first(result_doc, "//Success")
  #    if result.text.eql?'TRUE'
  #      result_file = File.new(output_file_name)
  #      output_doc = Document.new(result_file)
  #      #index=1;
  #      output_doc.root.each_element do |system|
  #        if index > 0
  #          key= "#{system.name()}#{@seperator}#{index}"
  #        else
  #          key= "#{system.name()}"
  #        end
  #        read_node(system,key,0)
  #        index=index+1
  #      end
  #    end
  #    @response_map
  #  end

  def parse_diskfolder_xml(result_file_name, output_file_name)
    result_file = File.new(result_file_name)
    result_doc = Document.new(result_file)
    result= XPath.first(result_doc, "//Success")
    if result.text.eql?'TRUE'
      result_file = File.new(output_file_name)
      output_doc = Document.new(result_file)
      index=1;
      output_doc.root.each_element do |system|
        key= "#{system.name()}#{@seperator}#{index}"
        read_diskfolder_node(system,key)
        index=index+1
      end
    end
    @response_map
  end

  #  def read_diskfolder_node(node,key_name)
  #    if node.has_elements?
  #      node.each_element do |child|
  #        read_node(child,key_name)
  #      end
  #    else
  #      puts node.parent
  #      key_name="#{key_name}#{@seperator}#{node.name()}"
  #      self.response_map[key_name]=node.text
  #    end
  #    key_name
  #  end

  def retrieve_server_properties(server_file_name)
       server_file = File.new(server_file_name)
       result_doc = Document.new(server_file)
       prop_map=Hash.new
       result= XPath.first(result_doc, "//server/Name")
       prop_map[result.name]=result.text
       result= XPath.first(result_doc, "//server/WWN_List")
       module_path_list=result.text.split(':')
       prop_map[result.name]=module_path_list
       volume_list=Array.new
       index=0
       result= XPath.each(result_doc, "//server/Mappings/mapping/Volume") do |volume|
         volume_list[index] = volume.text
         index+=1
       end
      prop_map["Volume"]=volume_list
      prop_map
  end


  def read_diskfolder_node(node,key_name)
    if node.has_elements?
      node.each_element do |child|
        read_diskfolder_node(child,key_name)
      end
    else
      if node.parent.name().eql?"StorageType" then  key_name="#{key_name}#{@seperator}StorageType#{@seperator}#{get_index_value(node.parent)}#{@seperator}#{node.name()}"
      else
        key_name="#{key_name}#{@seperator}#{node.name()}"
      end
      self.response_map[key_name]=node.text
    end
    key_name
  end

  def get_index_value(node)
    node.elements["Index"].text
  end

  public

  def return_response
    @response_map
  end

end





