# class that finds annotations and makes thier lighthouse tickets
module LighthouseAddons
  class SourceAnnotation
    
    attr_accessor :enumerator, :lh
  
    def initialize(tag)
      @lh         = LighthouseAddons::Authentication.new
      @enumerator = SourceAnnotationExtractor.new(tag).find(@lh.directories)
    end
  
    def self.enumerate(tag, options={})
      annotater   = new(tag)
      lh          = annotater.lh
      enumerator  = annotater.enumerator
      unchanged_tickets = []
      
      if enumerator.empty?
        puts "No tags found to replace, exiting..."
        exit
      end
      
      lh.authenticate
      
      enumerator.each do |path, annotations|
        puts "#{path}:"
        old_data = File.readlines(path)
        data = old_data.dup
        lines_deleted = 0
        annotations.each do |annotation|
          if annotation.text =~ /^\[(\d+)\]/
            unchanged_tickets << $1
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
	    ticket.assigned_user_id = lh.responsible if lh.responsible
            ticket.save
            ticket_url = "http://#{lh.account}.lighthouseapp.com/projects/#{lh.project_id}-#{lh.project.permalink}/tickets/#{ticket.id}-#{ticket.permalink}/"
            # ticket_url = "http://#{lh.account}.lighthouseapp.com/projects/#{lh.project_id}-#{lh.project.permalink}/tickets/15-todo-userrb-87"
            data[annotation.line-1] = data[annotation.line-1].gsub(annotation.text, "[#{ticket.id}] - #{annotation.text} - #{ticket_url}")
            puts "* Ticket: #{ticket.id} created - #{less(annotation.to_s(options),100)} "
          end
        end
        File.open(path,'w'){|f| f.write(data)} unless old_data == data
      end
      puts "\nThe following tickets have not been modified: #{unchanged_tickets.join(', ')}" unless unchanged_tickets.empty?
    end
  end  
end
