require File.join(File.dirname(__FILE__),'lighthouse')
require File.join(File.dirname(__FILE__),'pdfwriter')

class Object
  def less(text, max)
    return "" if text.nil?
    text.length > max ? text[0..max] + '...' : text
  end
end

module LighthouseAddons
  class LighthouseAuthorization
    attr_accessor :account, :username, :password, :project_id, :resolved_status, :project
    def initialize
      config_file       = File.expand_path(File.dirname(__FILE__) + '../../../../../config/lighthouse.yml')
      config            = YAML::load(File.open(config_file))
      @account          = config['account']
      @username         = config['username']
      @password         = config['password']
      @project_id       = config['project_id']
      @resolved_status  = config['resolved_status']
    end
    
    def connect
      Lighthouse.account = @account
      Lighthouse.authenticate(@username, @password)
      @project = Lighthouse::Project.find(@project_id)
    end
  end
  
  class LighthouseTicketPrinter
    def self.enumerate(tags_or_tickets, options={})
      new(tags_or_tickets, options)
    end
        
    attr_accessor :lhauth, :pdf, :tickets, :project_title
    
    def initialize(tags_or_tickets, options={})
      if tags_or_tickets =~ /OPTIMIZE|TODO|FIXME/
        annotater = LighthouseAddons::LighthouseSourceAnnotation.new(tags_or_tickets)
        lh          = annotater.lh
        enumerator  = annotater.enumerator
        
        if enumerator.empty?
          puts "No tags found to replace, exiting..."
          exit
        end
        
        lh.connect
        
        @tickets = enumerator.collect { |path, annotations| annotations.collect {|annotation| $1 if annotation.text =~ /^\[(\d+)\]/ }}.flatten
      else
        @tickets = tags_or_tickets.inject([]) { |tc, t| tc << (t =~ /(\d+)-(\d+)/ ? eval("(#{$1}..#{$2}).to_a") : t.to_i if t.to_i > 0) }.flatten.compact.uniq  
      end
      
      @lhauth = LighthouseAddons::LighthouseAuthorization.new
      @pdf = PdfWriter.new(File.open('tickets.pdf', 'wb'), 'LighthouseTickets', :mm)
      @lhauth.connect
      @project_title = @lhauth.project.name
      @tickets.each do |ticket_id| 
        begin
          ticket = Lighthouse::Ticket.find(ticket_id, :params => {:project_id => @lhauth.project_id})
        rescue
         puts "  * [NOT-FOUND] Ticket #{ticket_id}"
        else
          print(ticket)        
        end
      end
      @pdf.writeEnd
      exit
    end
    
    def print(ticket)
      @pdf.newPage
      @pdf.writeText(10, 285, "Project: #{less(@project_title, 60)}", :fontsize => 12)
      @pdf.writeText(10, 270, "LH # #{ticket.number} - #{less(ticket.title, 60)}", :fontsize => 18, :bold => true)
      @pdf.writeLine(10, 265, 200, 265)
      @pdf.writeTxtBox(260, 10, 155, "#{less(ticket.versions.first.body, 4500)}")
      @pdf.writeLine(10, 25, 200, 25)
      @pdf.writeText(10, 20, "Estimate:", :fontsize => 12)
      @pdf.writeText(10, 10, "Actual Time:", :fontsize => 12)
      @pdf.endPage
      puts "  * [PRINTED] Ticket #{ticket.number}"
    end    
  end
  
  class LighthouseSourceAnnotation
    attr_accessor :enumerator, :lh
  
    def initialize(tag)
      @lh         = LighthouseAuthorization.new
      @enumerator = SourceAnnotationExtractor.new(tag).find(%w(app lib test spec))
    end
  
    def self.enumerate(tag, options={})
      annotater   = new(tag)
      lh          = annotater.lh
      enumerator  = annotater.enumerator
      
      if enumerator.empty?
        puts "No tags found to replace, exiting..."
        exit
      end
      
      lh.connect
      
      enumerator.each do |path, annotations|
        puts "#{path}:"
        old_data = File.readlines(path)
        data = old_data.dup
        lines_deleted = 0
        annotations.each do |annotation|
          if annotation.text =~ /^\[(\d+)\]/
            puts "  * [NOT CHANGED] - Ticket: #{$1}"
          elsif annotation.text =~ /^\[(\d+)\:[f|F]\]/
            ticket = Lighthouse::Ticket.find($1, :params => { :project_id => lh.project_id })
            ticket.state = lh.resolved_status
            ticket.save
            data -= [data[annotation.line-lines_deleted-1]]
            lines_deleted += 1
            puts "  * [#{lh.resolved_status.upcase}] - Ticket: #{ticket.id}"
          else
            ticket = Lighthouse::Ticket.new(:project_id => lh.project_id)
            str = annotation.text
            tags = str.scan(/#([\w\-_\d]*)/).flatten
            tags.each {|tag| str = str.gsub('#'+tag, tag)}
            title = str.match(/\*(.*)\*/) ? $1 : "#{str[0..25]}..."
            str = str.gsub('*'+title+'*', title)
            str = str.gsub('..'+$1+'..', '<code>'+$1+'</code>') if str.match(/\.\.(.*)\.\./)
            ticket.title = "[#{annotation.tag}] - #{title} - #{path.split('/').last} - #{annotation.line}"
            ticket.body = str
            ticket.tags = tags
            ticket.save
            ticket_url = "http://#{lh.account}.lighthouseapp.com/projects/#{lh.project_id}-#{lh.project.permalink}/tickets/#{ticket.id}-#{ticket.permalink}/"
            # ticket_url = "http://#{lh.account}.lighthouseapp.com/projects/#{lh.project_id}-#{lh.project.permalink}/tickets/15-todo-userrb-87"
            data[annotation.line-1] = data[annotation.line-1].gsub(annotation.text, "[#{ticket.id}] - #{annotation.text} - #{ticket_url}")
            puts "* Ticket: #{ticket.id} created - #{less(annotation.to_s(options),100)} "
          end
        end
        File.open(path,'w'){|f| f.write(data)} unless old_data == data
      end
    end
  end
end