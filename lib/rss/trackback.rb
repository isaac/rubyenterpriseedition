require 'rss/1.0'
require 'rss/2.0'

module RSS

  TRACKBACK_PREFIX = 'trackback'
  TRACKBACK_URI = 'http://madskills.com/public/xml/rss/module/trackback/'

  RDF.install_ns(TRACKBACK_PREFIX, TRACKBACK_URI)
  Rss.install_ns(TRACKBACK_PREFIX, TRACKBACK_URI)

	module BaseTrackBackModel
    def trackback_validate(tags)
			raise unless @do_validate
      counter = {}
      %w(ping about).each do |x|
				counter["#{TRACKBACK_PREFIX}_#{x}"] = 0
			end

      tags.each do |tag|
        key = "#{TRACKBACK_PREFIX}_#{tag}"
        raise UnknownTagError.new(tag, TRACKBACK_URI) unless counter.has_key?(key)
        counter[key] += 1
				if tag != "about" and counter[key] > 1
					raise TooMuchTagError.new(tag, tag_name)
				end
			end

			if counter["#{TRACKBACK_PREFIX}_ping"].zero? and
					counter["#{TRACKBACK_PREFIX}_about"].nonzero?
				raise MissingTagError.new("#{TRACKBACK_PREFIX}:ping", tag_name)
			end
		end
	end

  module TrackBackModel10
    extend BaseModel
		include BaseTrackBackModel

		def self.append_features(klass)
			super

			unless klass.class == Module
				%w(ping).each do |x|
					klass.install_have_child_element("#{TRACKBACK_PREFIX}_#{x}")
				end
				
				%w(about).each do |x|
					klass.install_have_children_element("#{TRACKBACK_PREFIX}_#{x}")
				end
			end
		end

		class Ping < Element
			include RSS10

			class << self

				def required_prefix
					TRACKBACK_PREFIX
				end
				
				def required_uri
					TRACKBACK_URI
				end

			end
			
			[
				["resource", ::RSS::RDF::URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			def initialize(resource=nil)
				super()
				@resource = resource
			end

			def to_s(convert=true)
				if @resource
					rv = %Q!<#{TRACKBACK_PREFIX}:ping #{::RSS::RDF::PREFIX}:resource="#{h @resource}"/>!
					rv = @converter.convert(rv) if convert and @converter
					rv
				else
					''
				end
			end

			private
			def _attrs
				[
					["resource", true],
				]
			end

		end

		class About < Element
			include RSS10

			class << self
				
				def required_prefix
					TRACKBACK_PREFIX
				end
				
				def required_uri
					TRACKBACK_URI
				end

			end
			
			[
				["resource", ::RSS::RDF::URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			def initialize(resource=nil)
				super()
				@resource = resource
			end

			def to_s(convert=true)
				if @resource
					rv = %Q!<#{TRACKBACK_PREFIX}:about #{::RSS::RDF::PREFIX}:resource="#{h @resource}"/>!
					rv = @converter.convert(rv) if convert and @converter
					rv
				else
					''
				end
			end

			private
			def _attrs
				[
					["resource", true],
				]
			end

		end
	end

	module TrackBackModel20
		include BaseTrackBackModel
		extend BaseModel

		def self.append_features(klass)
			super

			unless klass.class == Module
				%w(ping).each do |x|
					var_name = "#{TRACKBACK_PREFIX}_#{x}"
					klass.install_have_child_element(var_name)
					klass.module_eval(<<-EOC)
						alias _#{var_name} #{var_name}
						def #{var_name}
							@#{var_name} and @#{var_name}.content
						end

						alias _#{var_name}= #{var_name}=
						def #{var_name}=(content)
							@#{var_name} = new_with_content_if_need(#{x.capitalize}, content)
						end
					EOC
				end
				
				[%w(about s)].each do |x, postfix|
					var_name = "#{TRACKBACK_PREFIX}_#{x}"
					klass.install_have_children_element(var_name)
					klass.module_eval(<<-EOC)
						alias _#{var_name}#{postfix} #{var_name}#{postfix}
						def #{var_name}#{postfix}
							@#{var_name}.collect {|x| x.content}
						end

						alias _#{var_name} #{var_name}
						def #{var_name}(*args)
							if args.empty?
								@#{var_name}.first and @#{var_name}.first.content
							else
								ret = @#{var_name}.send("[]", *args)
								if ret.is_a?(Array)
									ret.collect {|x| x.content}
								else
									ret.content
								end
							end
						end

						alias _#{var_name}= #{var_name}=
						alias _set_#{var_name} set_#{var_name}
						def #{var_name}=(*args)
							if args.size == 1
								item = new_with_content_if_need(#{x.capitalize}, args[0])
								@#{var_name}.push(item)
							else
								new_val = args.last
								if new_val.is_a?(Array)
									new_val = new_value.collect do |val|
										new_with_content_if_need(#{x.capitalize}, val)
									end
								else
									new_val = new_with_content_if_need(#{x.capitalize}, new_val)
								end
								@#{var_name}.send("[]=", *(args[0..-2] + [new_val]))
							end
						end
						alias set_#{var_name} #{var_name}=
					EOC
				end
			end

			private
			def new_with_content(klass, content)
				obj = klass.new
				obj.content = content
				obj
			end

			def new_with_content_if_need(klass, content)
				if content.is_a?(klass)
					content
				else
					new_with_content(klass, content)
				end
			end

		end

		class Ping < Element
			include RSS09

			content_setup

			class << self

				def required_prefix
					TRACKBACK_PREFIX
				end
				
				def required_uri
					TRACKBACK_URI
				end

			end
			
			def to_s(convert=true)
				if @content
					rv = %Q!<#{TRACKBACK_PREFIX}:ping>#{h @content}</#{TRACKBACK_PREFIX}:ping>!
					rv = @converter.convert(rv) if convert and @converter
					rv
				else
					''
				end
			end

		end

		class About < Element
			include RSS09

			content_setup

			class << self
				
				def required_prefix
					TRACKBACK_PREFIX
				end
				
				def required_uri
					TRACKBACK_URI
				end

			end
			
			def to_s(convert=true)
				if @content
					rv = %Q!<#{TRACKBACK_PREFIX}:about>#{h @content}</#{TRACKBACK_PREFIX}:about>!
					rv = @converter.convert(rv) if convert and @converter
					rv
				else
					''
				end
			end

		end
	end

  class RDF
    class Item; include TrackBackModel10; end
  end

	class Rss
		class Channel
			class Item; include TrackBackModel20; end
		end
	end

end