require File.dirname(__FILE__) + '/../spec_helper'

describe "SAXMachine" do
  describe "element" do
    describe "when parsing a single element" do
      before :each do
        @klass = Class.new do
          include SAXMachine
          element :title
        end
      end

      it "should provide an accessor" do
        document = @klass.new
        document.title = "Title"
        document.title.should == "Title"
      end
      
      it "should allow introspection of the elements" do
        @klass.column_names.should =~ [:title]
      end

      it "should not overwrite the setter if there is already one present" do
        @klass = Class.new do
          def title=(val)
            @title = "#{val} **"
          end
          include SAXMachine
          element :title
        end
        document = @klass.new
        document.title = "Title"
        document.title.should == "Title **"
      end
      describe "the class attribute" do
        before(:each) do
          @klass = Class.new do
            include SAXMachine
            element :date, :class => DateTime
          end
          @document = @klass.new
          @document.date = DateTime.now.to_s
        end
        it "should be available" do
          @klass.data_class(:date).should == DateTime
        end
      end
      describe "the required attribute" do
        it "should be available" do
          @klass = Class.new do
            include SAXMachine
            element :date, :required => true
          end
          @klass.required?(:date).should be_true
        end
      end
      
      it "should not overwrite the accessor when the element is not present" do
        document = @klass.new
        document.title = "Title"
        document.parse("<foo></foo>")
        document.title.should == "Title"
      end

      it "should *not* overwrite the value when the element is present (new behaviour!)" do
        document = @klass.new
        document.title = "Old title"
        document.parse("<title>New title</title>")
        document.title.should == "Old title"
      end

      it "should save the element text into an accessor" do
        document = @klass.parse("<title>My Title</title>")
        document.title.should == "My Title"
      end
      
      it "should save cdata into an accessor" do
        document = @klass.parse("<title><![CDATA[A Title]]></title>")
        document.title.should == "A Title"
      end

      it "should save the element text into an accessor when there are multiple elements" do
        document = @klass.parse("<xml><title>My Title</title><foo>bar</foo></xml>")
        document.title.should == "My Title"
      end

      it "should save the first element text when there are multiple of the same element" do
        document = @klass.parse("<xml><title>My Title</title><title>bar</title></xml>")
        document.title.should == "My Title"    
      end
    end

    describe "when parsing multiple elements" do
      before :each do
        @klass = Class.new do
          include SAXMachine
          element :title
          element :name
        end
      end

      it "should save the element text for a second tag" do
        document = @klass.parse("<xml><title>My Title</title><name>Paul</name></xml>")
        document.name.should == "Paul"
        document.title.should == "My Title"
      end
    end

    describe "when using options for parsing elements" do
      describe "using the 'as' option" do
        before :each do
          @klass = Class.new do
            include SAXMachine
            element :description, :as => :summary
          end
        end

        it "should provide an accessor using the 'as' name" do
          document = @klass.new
          document.summary = "a small summary"
          document.summary.should == "a small summary"
        end

        it "should save the element text into the 'as' accessor" do
          document = @klass.parse("<description>here is a description</description>")
          document.summary.should == "here is a description"
        end
      end
      
      describe "using the :with option" do
        describe "and the :value option" do
          before :each do
            @klass = Class.new do
              include SAXMachine
              element :link, :value => :href, :with => {:foo => "bar"}
            end
          end
          
          it "should escape correctly the ampersand" do
            document = @klass.parse("<link href='http://api.flickr.com/services/feeds/photos_public.gne?id=49724566@N00&amp;lang=en-us&amp;format=atom' foo='bar'>asdf</link>")
            document.link.should == "http://api.flickr.com/services/feeds/photos_public.gne?id=49724566@N00&lang=en-us&format=atom"
          end
          
          it "should save the value of a matching element" do
            document = @klass.parse("<link href='test' foo='bar'>asdf</link>")
            document.link.should == "test"
          end
          
          it "should save the value of the first matching element" do
            document = @klass.parse("<xml><link href='first' foo='bar' /><link href='second' foo='bar' /></xml>")
            document.link.should == "first"
          end
          
          describe "and the :as option" do
            before :each do
              @klass = Class.new do
                include SAXMachine
                element :link, :value => :href, :as => :url, :with => {:foo => "bar"}
                element :link, :value => :href, :as => :second_url, :with => {:asdf => "jkl"}
              end
            end
            
            it "should save the value of the first matching element" do
              document = @klass.parse("<xml><link href='first' foo='bar' /><link href='second' asdf='jkl' /><link href='second' foo='bar' /></xml>")
              document.url.should == "first"
              document.second_url.should == "second"
            end            
          end
        end
        
        describe "with only one element" do
          before :each do
            @klass = Class.new do
              include SAXMachine
              element :link, :with => {:foo => "bar"}
            end
          end

          it "should save the text of an element that has matching attributes" do
            document = @klass.parse("<link foo=\"bar\">match</link>")
            document.link.should == "match"
          end

          it "should not save the text of an element that doesn't have matching attributes" do
            document = @klass.parse("<link>no match</link>")
            document.link.should be_nil
          end

          it "should save the text of an element that has matching attributes when it is the second of that type" do
            document = @klass.parse("<xml><link>no match</link><link foo=\"bar\">match</link></xml>")
            document.link.should == "match"          
          end
          
          it "should save the text of an element that has matching attributes plus a few more" do
            document = @klass.parse("<xml><link>no match</link><link asdf='jkl' foo='bar'>match</link>")
            document.link.should == "match"
          end
        end
        
        describe "with multiple elements of same tag" do
          before :each do
            @klass = Class.new do
              include SAXMachine
              element :link, :as => :first, :with => {:foo => "bar"}
              element :link, :as => :second, :with => {:asdf => "jkl"}
            end
          end
          
          it "should match the first element" do
            document = @klass.parse("<xml><link>no match</link><link foo=\"bar\">first match</link><link>no match</link></xml>")
            document.first.should == "first match"
          end
          
          it "should match the second element" do
            document = @klass.parse("<xml><link>no match</link><link foo='bar'>first match</link><link asdf='jkl'>second match</link><link>hi</link></xml>")
            document.second.should == "second match"
          end
        end
      end # using the 'with' option
      
      describe "using the 'value' option" do
        before :each do
          @klass = Class.new do
            include SAXMachine
            element :link, :value => :foo
          end
        end
        
        it "should save the attribute value" do
          document = @klass.parse("<link foo='test'>hello</link>")
          document.link.should == 'test'
        end
        
        it "should save the attribute value when there is no text enclosed by the tag" do
          document = @klass.parse("<link foo='test'></link>")
          document.link.should == 'test'
        end
        
        it "should save the attribute value when the tag close is in the open" do
          document = @klass.parse("<link foo='test'/>")
          document.link.should == 'test'
        end
        
        it "should save two different attribute values on a single tag" do
          @klass = Class.new do
            include SAXMachine
            element :link, :value => :foo, :as => :first
            element :link, :value => :bar, :as => :second
          end
          document = @klass.parse("<link foo='foo value' bar='bar value'></link>")
          document.first.should == "foo value"
          document.second.should == "bar value"
        end
        
        it "should not fail if one of the attribute hasn't been defined" do
          @klass = Class.new do
            include SAXMachine
            element :link, :value => :foo, :as => :first
            element :link, :value => :bar, :as => :second
          end
          document = @klass.parse("<link foo='foo value'></link>")
          document.first.should == "foo value"
          document.second.should be_nil
        end
      end
      
      describe "when desiring both the content and attributes of an element" do
        before :each do
          @klass = Class.new do
            include SAXMachine
            element :link
            element :link, :value => :foo, :as => :link_foo
            element :link, :value => :bar, :as => :link_bar
          end
        end

        it "should parse the element and attribute values" do
          document = @klass.parse("<link foo='test1' bar='test2'>hello</link>")
          document.link.should == 'hello'
          document.link_foo.should == 'test1'
          document.link_bar.should == 'test2'
        end
      end

      describe "when specifying namespaces" do
        before :all do
          @klass = Class.new do
            include SAXMachine
            element :a, :xmlns => 'urn:test'
            element :b, :xmlns => ['', 'urn:test']
          end
        end

        it "should get the element with the xmlns" do
          document = @klass.parse("<a xmlns='urn:test'>hello</a>")
          document.a.should == 'hello'
        end

        it "shouldn't get the element without the xmlns" do
          document = @klass.parse("<a>hello</a>")
          document.a.should be_nil
        end

        it "shouldn't get the element with the wrong xmlns" do
          document = @klass.parse("<a xmlns='urn:test2'>hello</a>")
          document.a.should be_nil
        end

        it "should get an element without xmlns if the empty namespace is desired" do
          document = @klass.parse("<b>hello</b>")
          document.b.should == 'hello'
        end

        it "should get an element with the right prefix" do
          document = @klass.parse("<p:a xmlns:p='urn:test'>hello</p:a>")
          document.a.should == 'hello'
        end

        it "should not get an element with the wrong prefix" do
          document = @klass.parse("<x:a xmlns:p='urn:test' xmlns:x='urn:test2'>hello</x:a>")
          document.a.should be_nil
        end

        it "should get a prefixed element without xmlns if the empty namespace is desired" do
          pending "this needs a less pickier nokogiri push parser"
          document = @klass.parse("<x:b>hello</x:b>")
          document.b.should == 'hello'
        end

        it "should get the namespaced element even it's not first" do
          document = @klass.parse("<root xmlns:a='urn:test'><a>foo</a><a>foo</a><a:a>bar</a:a></root>")
          document.a.should == 'bar'
        end

        it "should parse multiple namespaces" do
          klass = Class.new do
            include SAXMachine
            element :a, :xmlns => 'urn:test'
            element :b, :xmlns => 'urn:test2'
          end
          document = klass.parse("<root xmlns='urn:test' xmlns:b='urn:test2'><b:b>bar</b:b><a>foo</a></root>")
          document.a.should == 'foo'
          document.b.should == 'bar'
        end

        context "when passing a default namespace" do
          before :all do
            @xmlns = 'urn:test'
            class Inner
              include SAXMachine
              element :a, :xmlns => @xmlns
            end
            @outer = Class.new do
              include SAXMachine
              elements :root, :default_xmlns => @xmlns, :class => Inner
            end
          end

          it "should replace the empty namespace with a default" do
            document = @outer.parse("<root><a>Hello</a></root>")
            document.root[0].a.should == 'Hello'
          end

          it "should not replace another namespace" do
            document = @outer.parse("<root xmlns='urn:test2'><a>Hello</a></root>")
            document.root[0].a.should == 'Hello'
          end
        end
      end
      
    end
  end
  
  describe "elements" do
    describe "when parsing multiple elements" do
      before :all do
        @klass = Class.new do
          include SAXMachine
          elements :entry, :as => :entries
        end
      end
      
      it "should provide a collection accessor" do
        document = @klass.new
        document.entries << :foo
        document.entries.should == [:foo]
      end
      
      it "should parse a single element" do
        document = @klass.parse("<entry>hello</entry>")
        document.entries.should == ["hello"]
      end
      
      it "should parse multiple elements" do
        document = @klass.parse("<xml><entry>hello</entry><entry>world</entry></xml>")
        document.entries.should == ["hello", "world"]
      end
      
      it "should parse multiple elements when taking an attribute value" do
        attribute_klass = Class.new do
          include SAXMachine
          elements :entry, :as => :entries, :value => :foo
        end
        doc = attribute_klass.parse("<xml><entry foo='asdf' /><entry foo='jkl' /></xml>")
        doc.entries.should == ["asdf", "jkl"]
      end
    end
    
    describe "when using the class option" do
      before :each do
        class Foo
          include SAXMachine
          element :title
        end
        @klass = Class.new do
          include SAXMachine
          elements :entry, :as => :entries, :class => Foo
        end
      end
      
      it "should parse a single element with children" do
        document = @klass.parse("<entry><title>a title</title></entry>")
        document.entries.size.should == 1
        document.entries.first.title.should == "a title"
      end
      
      it "should parse multiple elements with children" do
        document = @klass.parse("<xml><entry><title>title 1</title></entry><entry><title>title 2</title></entry></xml>")
        document.entries.size.should == 2
        document.entries.first.title.should == "title 1"
        document.entries.last.title.should == "title 2"
      end
      
      it "should not parse a top level element that is specified only in a child" do
        document = @klass.parse("<xml><title>no parse</title><entry><title>correct title</title></entry></xml>")
        document.entries.size.should == 1
        document.entries.first.title.should == "correct title"
      end
      
      it "should parse out an attribute value from the tag that starts the collection" do
        class Foo
          element :entry, :value => :href, :as => :url
        end
        document = @klass.parse("<xml><entry href='http://pauldix.net'><title>paul</title></entry></xml>")
        document.entries.size.should == 1
        document.entries.first.title.should == "paul"
        document.entries.first.url.should == "http://pauldix.net"
      end
    end    

    describe "when desiring sax events" do
      XHTML_XMLNS = "http://www.w3.org/1999/xhtml"

      before :all do
        @klass = Class.new do
          include SAXMachine
          elements :body, :events => true
        end
      end

      it "should parse a simple child" do
        document = @klass.parse("<body><p/></body>")
        document.body[0].should == [[:start_element, "", "p", []],
                                    [:end_element, "", "p"]]
      end
      it "should parse a simple child with text" do
        document = @klass.parse("<body><p>Hello</p></body>")
        document.body[0].should == [[:start_element, "", "p", []],
                                    [:chars, "Hello"],
                                    [:end_element, "", "p"]]
      end
      it "should parse nested children" do
        document = @klass.parse("<body><p><span/></p></body>")
        document.body[0].should == [[:start_element, "", "p", []],
                                    [:start_element, "", "span", []],
                                    [:end_element, "", "span"],
                                    [:end_element, "", "p"]]
      end
      it "should parse multiple children" do
        document = @klass.parse("<body><p>Hello</p><p>World</p></body>")
        document.body[0].should == [[:start_element, "", "p", []],
                                    [:chars, "Hello"],
                                    [:end_element, "", "p"],
                                    [:start_element, "", "p", []],
                                    [:chars, "World"],
                                    [:end_element, "", "p"]]
      end
      it "should pass namespaces" do
        document = @klass.parse("<body xmlns='#{XHTML_XMLNS}'><p/></body>")
        document.body[0].should == [[:start_element, XHTML_XMLNS, "p", []],
                                    [:end_element, XHTML_XMLNS, "p"]]
      end
    end
  end
  
  describe "full example" do
    XMLNS_ATOM = "http://www.w3.org/2005/Atom"
    XMLNS_FEEDBURNER = "http://rssnamespace.org/feedburner/ext/1.0"

    before :each do
      @xml = File.read('spec/sax-machine/atom.xml')
      class AtomEntry
        include SAXMachine
        element :title
        element :name, :as => :author
        element :origLink, :as => :orig_link, :xmlns => XMLNS_FEEDBURNER
        element :summary
        element :content
        element :published
      end
        
      class Atom
        include SAXMachine
        element :title
        element :link, :value => :href, :as => :url, :with => {:type => "text/html"}
        element :link, :value => :href, :as => :feed_url, :with => {:type => "application/atom+xml"}
        elements :entry, :as => :entries, :class => AtomEntry, :xmlns => XMLNS_ATOM
      end
    end # before
    
    it "should parse the url" do
      f = Atom.parse(@xml)
      f.url.should == "http://www.pauldix.net/"
    end

    it "should parse all entries" do
      f = Atom.parse(@xml)
      f.entries.length.should == 5
    end

    it "should parse the feedburner:origLink" do
      f = Atom.parse(@xml)
      f.entries[0].orig_link.should == 'http://www.pauldix.net/2008/09/marshal-data-to.html'
    end
  end

  describe "another full example" do

    RSS_XMLNS = 'http://purl.org/rss/1.0/'
    ATOM_XMLNS = 'http://www.w3.org/2005/Atom'
    class Entry
      include SAXMachine
      element :title, :xmlns => RSS_XMLNS
      element :title, :xmlns => ATOM_XMLNS
      element :link, :xmlns => RSS_XMLNS
      element :link, :xmlns => ATOM_XMLNS, :value => 'href'
    end
    class Channel
      include SAXMachine
      element :title, :xmlns => RSS_XMLNS
      element :title, :xmlns => ATOM_XMLNS
      element :link, :xmlns => RSS_XMLNS
      element :link, :xmlns => ATOM_XMLNS, :value => 'href'
      elements :entry, :as => :entries, :class => Entry
      elements :item, :as => :entries, :class => Entry
    end
    class Root
      include SAXMachine
      elements :rss, :as => :channels, :default_xmlns => RSS_XMLNS, :class => Channel
      elements :feed, :as => :channels, :default_xmlns => ATOM_XMLNS, :class => Channel
    end

    context "when parsing a complex example" do
      before :all do
        @document = Root.parse(<<-eoxml).channels[0]
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" 
                   xmlns:content="http://purl.org/rss/1.0/modules/content/"
                   xmlns:wfw="http://wellformedweb.org/CommentAPI/"
                   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:cc="http://web.resource.org/cc/">
  <channel>
    <title>Delicious/tag/pubsubhubbub</title>
    <atom:link rel="self" type="application/rss+xml" href="http://feeds.delicious.com/v2/rss/tag/pubsubhubbub?count=15"/>
    <link>http://delicious.com/tag/pubsubhubbub</link>
    <description>recent bookmarks tagged pubsubhubbub</description>
  </channel>
</rss>
eoxml
      end
      it "should parse the title" do
        @document.title.should == 'Delicious/tag/pubsubhubbub'
      end
      it "should parse the link" do
        @document.link.should == 'http://feeds.delicious.com/v2/rss/tag/pubsubhubbub?count=15'
      end
    end
  end  
  
  describe "yet another full example" do
  
    context "when parsing a Twitter example" do
      before :all do
        
        RSS_XMLNS = ['http://purl.org/rss/1.0/', '']
        
        ATOM_XMLNS = 'http://www.w3.org/2005/Atom' unless defined? ATOM_XMLNS
        class Link
          include SAXMachine
        end
        
        class Entry
          include SAXMachine
          element   :title,        :xmlns => RSS_XMLNS
          element   :link,         :xmlns => RSS_XMLNS,   :as => :entry_link
          element   :title,        :xmlns => ATOM_XMLNS,  :as => :title
          elements  :link,         :xmlns => ATOM_XMLNS,  :as => :links,      :class => Link
        end
        
        class Feed
          include SAXMachine
          element   :title,        :xmlns => RSS_XMLNS,  :as => :title
          element   :link,         :xmlns => RSS_XMLNS,  :as => :feed_link
          elements  :item,         :xmlns => RSS_XMLNS,  :as => :entries,         :class => Entry
          element   :title,        :xmlns => ATOM_XMLNS, :as => :title
          elements  :link,         :xmlns => ATOM_XMLNS, :as => :links,           :class => Link
        end
        
        @document = Feed.parse(<<-eoxml)
<?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
          <channel>
            <atom:link type="application/rss+xml" rel="self" href="http://twitter.com/statuses/user_timeline/5381582.rss"/>
            <title>Twitter / julien51</title>
            <link>http://twitter.com/julien51</link>
            <description>Twitter updates from julien / julien51.</description>
            <language>en-us</language>
            <ttl>40</ttl>
          <item>
            <title>julien51: @github :  I get an error when trying to build one of my gems (julien51-sax-machine), it seems related to another gem's gemspec.</title>
            <description>julien51: @github :  I get an error when trying to build one of my gems (julien51-sax-machine), it seems related to another gem's gemspec.</description>
            <pubDate>Thu, 30 Jul 2009 01:00:30 +0000</pubDate>
            <guid>http://twitter.com/julien51/statuses/2920716033</guid>
            <link>http://twitter.com/julien51/statuses/2920716033</link>
          </item>
          <item>
            <title>julien51: Hum, San Francisco's summer are delightful. http://bit.ly/VeXt4</title>
            <description>julien51: Hum, San Francisco's summer are delightful. http://bit.ly/VeXt4</description>
            <pubDate>Wed, 29 Jul 2009 23:07:32 +0000</pubDate>
            <guid>http://twitter.com/julien51/statuses/2918869948</guid>
            <link>http://twitter.com/julien51/statuses/2918869948</link>
          </item>
          </channel>
        </rss>
eoxml
      end
      it "should parse the title" do
        @document.title.should == 'Twitter / julien51'
      end
      
      it "should find an entry" do
        @document.entries.length.should == 2
      end
    end
  end
end
