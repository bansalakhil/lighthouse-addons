require File.join(File.dirname(__FILE__),'../lib/lighthouse_addons')

desc "Enumerate all annotations and create lighthouse tickets"
task :lhnotes do
  LighthouseAddons::LighthouseSourceAnnotation.enumerate "OPTIMIZE|FIXME|TODO", :tag => true
end

namespace :lhnotes do
  ["OPTIMIZE", "FIXME", "TODO"].each do |annotation|
    desc "Enumerate all #{annotation} annotations and create lighthouse tickets"
    task annotation.downcase.intern do
      LighthouseAddons::LighthouseSourceAnnotation.enumerate annotation
    end
  end

  desc "Enumerate a custom annotation, specify with ANNOTATION=WTFHAX and create lighthouse tickets"
  task :custom do
    LighthouseAddons::LighthouseSourceAnnotation.enumerate ENV['ANNOTATION']
  end
  
  desc "Prints lighthouse tickets, specify ticket nos."
  task :print do
    LighthouseAddons::LighthouseTicketPrinter.enumerate(((ARGV[1..-1].blank? ? false : ARGV[1..-1])||"OPTIMIZE|FIXME|TODO"), :tag => true)
  end
    
  namespace :print do
    ["OPTIMIZE", "FIXME", "TODO"].each do |annotation|
      desc "Enumerate all #{annotation} annotations and create lighthouse tickets"
      task annotation.downcase.intern do
        LighthouseAddons::LighthouseTicketPrinter.enumerate annotation
      end
    end
  
    desc "Enumerate a custom annotation, specify with ANNOTATION=WTFHAX and create lighthouse tickets"
    task :custom do
      LighthouseAddons::LighthouseTicketPrinter.enumerate annotation
    end
  end  
end