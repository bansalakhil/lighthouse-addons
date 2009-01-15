require 'fileutils'

lighthouse_config = File.dirname(__FILE__) + '/../../../config/lighthouse.yml'
FileUtils.remove lighthouse_config if File.exist?(lighthouse_config)