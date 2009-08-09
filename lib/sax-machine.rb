$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))) unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require "cgi"

require "sax-machine/sax_document"
require "sax-machine/sax_handler"
require "sax-machine/sax_config"
require "sax-machine/sax_event_recorder"

module SAXMachine
  VERSION = "0.0.20"
end
