# Class the performs Authentication with LH
module LighthouseAddons
  class Printer
    
    # Print tickets by search string
    def self.string_search(q)
      lh = LighthouseAddons::Authentication.new
      lh.authenticate
      tickets = Lighthouse::Ticket.find(:all, :params => {:project_id => lh.project_id, :q => q})
      LighthouseAddons::Printer.print(tickets.collect(&:id))
    end
    
    # Print tickets by milestone
    def self.milestone(milestone_id)
      lh = LighthouseAddons::Authentication.new
      lh.authenticate
      milestone = Lighthouse::Milestone.find(:first, :params => {:project_id => lh.project_id, :id => milestone_id})
      string_search("milestone:'#{milestone.title}'")
    end
    
    # Print tickets by ticket nos.
    def self.tickets(tickets)
      filtered_tickets = tickets.inject([]) { |tc, t| tc << (t =~ /(\d+)-(\d+)/ ? eval("(#{$1}..#{$2}).to_a") : t.to_i if t.to_i > 0) }.flatten.compact.uniq
      LighthouseAddons::Printer.print(filtered_tickets)
    end
    
    # Print tickets by annotations
    def self.annotations(annotation)
      annotater = LighthouseAddons::SourceAnnotation.new(annotation)
      lh = annotater.lh
      enumerator = annotater.enumerator
      (puts("No tickets found."); exit) if enumerator.empty?
      lh.authenticate
      tickets = enumerator.collect { |path, annotations| annotations.collect {|annotation| $1 if annotation.text =~ /^\[(\d+)\]/ }}.flatten      
      LighthouseAddons::Printer.print(tickets)
    end
    
    private    
    def self.print(tickets)
      (puts("No tickets found."); exit) if tickets.empty?
      lh = LighthouseAddons::Authentication.new
      lh.authenticate
      pdf_data = ""
      pdf = PdfWriter.new(pdf_data, 'LighthouseTickets', :mm)
      tickets.each do|ticket_id| 
        begin
          ticket = Lighthouse::Ticket.find(ticket_id, :params => {:project_id => lh.project_id})
        rescue
         puts "  * [NOT-FOUND] Ticket #{ticket_id}"
        else
          pdf.newPage
          pdf.writeText(10, 285, "Project: #{less(lh.project.name, 60)}", :fontsize => 12)
          pdf.writeText(10, 270, "LH # #{ticket.number} - #{less(ticket.title, 60)}", :fontsize => 18, :bold => true)
          pdf.writeLine(10, 265, 200, 265)
          pdf.writeTxtBox(260, 10, 155, "#{less(ticket.versions.first.body, 4500)}")
          pdf.writeLine(10, 25, 200, 25)
          pdf.writeText(10, 20, "Estimate:", :fontsize => 12)
          pdf.writeText(10, 10, "Actual Time:", :fontsize => 12)
          pdf.endPage
          puts "  * [PRINTED] Ticket #{ticket.number}"
        end
      end
      if pdf_data.empty?
        puts "PDF not written, no tickets found."
      else
        pdf.writeEnd
        File.open('tickets.pdf', 'wb').write(pdf_data)
      end
      exit
    end
  end
end