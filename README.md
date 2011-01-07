# SAX Machine

A declarative sax parsing library backed by Nokogiri.

# Example Usage

    require 'sax-machine'

    # Class for parsing an atom entry out of a feedburner atom feed
    class AtomEntry
      include SAXMachine
      element :title
      # the :as argument makes this available through atom_entry.author instead of .name
      element :name, :as => :author
      element "feedburner:origLink", :as => :url
      element :summary
      element :content
      element :published
    end

    # Class for parsing Atom feeds
    class Atom
      include SAXMachine
      element :title
      # the :with argument means that you only match a link tag that has an attribute of :type => "text/html"
      # the :value argument means that instead of setting the value to the text between the tag,
      # it sets it to the attribute value of :href
      element :link, :value => :href, :as => :url, :with => {:type => "text/html"}
      element :link, :value => :href, :as => :feed_url, :with => {:type => "application/atom+xml"}
      elements :entry, :as => :entries, :class => AtomEntry
    end

    # you can then parse like this
    feed = Atom.parse(xml_text)
    # then you're ready to rock
    feed.title # => whatever the title of the blog is
    feed.url # => the main url of the blog
    feed.feed_url # => goes to the feedburner feed
 
    feed.entries.first.title # => title of the first entry
    feed.entries.first.author # => the author of the first entry
    feed.entries.first.url # => the permalink on the blog for this entry
    # etc ...

    # you can also use the elements method without specifying a class like so
    class SomeServiceResponse
      elements :message, :as => :messages
    end

    response = SomeServiceResponse.parse("<response><message>hi</message><message>world</message></response>")
    response.messages.first # => "hi"
    response.messages.last  # => "world"

# Install

* sudo gem install sporkmonger-sax-machine
