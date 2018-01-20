require 'rack'
require 'rack/server'
require 'json'
require 'fileutils'

module NEC

end


Dir[File.dirname(__FILE__) + '/nec_mock_server/*.rb'].each do |file|
  require(file.gsub('\\', '/').split('/lib/').last[0..-4])
end