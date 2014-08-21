Pod::Spec.new do |s|
  s.name         = "Harvest"
  s.version      = "0.1.0"
  s.summary      = "Client library for the Harvestd analytics collector"
  s.homepage     = "https://github.com/seanmcgary/harvestd-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Sean McGary" => "sean@seanmcgary.com" }
  s.source       = { :git => "https://github.com/seanmcgary/harvestd-ios.git", :tag => "0.1.0" }
  s.source_files = "Harvest"
  s.exclude_files = "Classes/Exclude"
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  s.dependency "AFNetworking", "2.3.1"

end
