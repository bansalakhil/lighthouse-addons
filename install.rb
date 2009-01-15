require 'fileutils'

lighthouse_config = File.dirname(__FILE__) + '/../../../config/lighthouse.yml'
FileUtils.cp File.dirname(__FILE__) + '/lighthouse.example', lighthouse_config unless File.exist?(lighthouse_config)