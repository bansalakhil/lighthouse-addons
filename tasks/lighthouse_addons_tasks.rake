require File.join(File.dirname(__FILE__),'../lib/lighthouse_addons')

# lhnotes
desc "Enumerate all annotations and create lighthouse tickets"
task :lhnotes do
  LighthouseAddons::SourceAnnotation.enumerate("OPTIMIZE|FIXME|TODO", :tag => true)
end

namespace :lhnotes do
  ["OPTIMIZE", "FIXME", "TODO"].each do |annotation|
    desc "Enumerate all #{annotation} annotations and create lighthouse tickets"
    task annotation.downcase.intern do
      LighthouseAddons::SourceAnnotation.enumerate(annotation)
    end
  end

  desc "Enumerate a custom annotation, specify with ANNOTATION=WTFHAX and create lighthouse tickets"
  task :custom do
    LighthouseAddons::SourceAnnotation.enumerate(ENV['ANNOTATION'])
  end
end

# lhprint
desc "Enumerate all annotations and create lighthouse tickets"
task :lhprint do
  LighthouseAddons::Printer.annotations("OPTIMIZE|FIXME|TODO")
end

namespace :lhprint do
  
  desc "print tickets by numbers"
  task :tickets do
    LighthouseAddons::Printer.tickets(ARGV[1..-1])
  end
  
  desc "print tickets by search string"
  task :search do
    LighthouseAddons::Printer.string_search(ARGV[1])
  end
  
  desc "print tickets by milestone_id"
  task :ms do
    LighthouseAddons::Printer.milestone(ARGV[1])
  end
  
  ["OPTIMIZE", "FIXME", "TODO"].each do |annotation|
    desc "Enumerate all #{annotation} annotations and print lighthouse tickets"
    task annotation.downcase.intern do
      LighthouseAddons::Printer.annotations(annotation)
    end
  end
  
  desc "Enumerate a custom annotation, specify with ANNOTATION=WTFHAX and create lighthouse tickets"
  task :custom do
    LighthouseAddons::Printer.annotations(ENV['ANNOTATION'])
  end
  
end