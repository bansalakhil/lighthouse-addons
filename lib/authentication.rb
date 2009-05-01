# Class the performs Authentication with LH
module LighthouseAddons
  class Authentication
    
    def self.authenticate
      new.authenticate
    end
    
    attr_accessor :account, :username, :password, :project_id, :resolved_status, :project, :responsible, :directories
    
    def initialize
      config_file       = File.expand_path(File.dirname(__FILE__) + '../../../../../config/lighthouse.yml')
      config            = YAML::load(File.open(config_file))
      @account          = config['account']
      @username         = config['username']
      @password         = config['password']
      @project_id       = config['project_id']
      @resolved_status  = config['resolved_status']
      @directories      = eval config['directories']
      @responsible      = config['responsible']
    end
    
    def authenticate
      Lighthouse.account = @account
      Lighthouse.authenticate(@username, @password)
      @project = Lighthouse::Project.find(@project_id)
    end

  end
end
