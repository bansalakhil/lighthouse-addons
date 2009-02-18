require File.join(File.dirname(__FILE__),'lighthouse')
require File.join(File.dirname(__FILE__),'pdfwriter')
require File.join(File.dirname(__FILE__),'authentication')
require File.join(File.dirname(__FILE__),'source_annotation')
require File.join(File.dirname(__FILE__),'printer')
# require 'pp'
# require 'yaml'

class Object
  def less(text, max)
    return "" if text.nil?
    text.length > max ? text[0..max] + '...' : text
  end
end

class String
  def write(str)
    self << str 
  end
end