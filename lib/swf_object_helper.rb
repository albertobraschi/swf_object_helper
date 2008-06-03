# Generates JavaScript and optionally alternative content for SWFObject v2.0:
# http://code.google.com/p/swfobject/wiki/documentation
#
# Pass a block with alternative content to also create a div containing it:
#
#   <% swf_object(...) do %>
#     <p>Get Flash, fool!</p>
#   <% end %>
#
# Like other helpers that take blocks, this will concatenate the generated code to
# the ERB output stream directly, so use <% %> instead of <%= %> if a block is given.
#
# Or, pass :alt => true to generate string output including default alternative content:
#
#   <%= swf_object(..., :id => 'alt_content', :alt => true) %>
#   # => <div id='alt_content'>This website requires ...</div><script ...
#
# or pass :alt => "some string" to put that in the alternative content:
#   <%= swf_object(..., :id => 'alt_content', :alt => "no flash") %>
#   # => <div id='alt_content'>no flash</div><script ...
#
# By default, or if you explicitly pass :alt => false, you will have to create the
# alternative content element yourself.
#
# Originally by Henrik N - http://henrik.nyh.se/ http://pastie.textmate.org/private/nu0hpwxmtcx0toi58j4kha
module SWFObjectHelper
  REQUIRED_ARGUMENTS = [ :url, :id, :width, :height, :version ]
  OPTIONAL_ARGUMENTS = [ :express_install_url ]
  HASH_ARGUMENTS     = [ :flashvars, :params, :attributes ]

  # Optional attributes specified http://kb.adobe.com/selfservice/viewContent.do?externalId=tn_12701
  # First value in possible values array is default
  OPTIONAL_ATTRIBUTES_POSSIBLE_VALUES = {
    :play              => [ 'true', 'false' ],
    :loop              => [ 'true', 'false' ],
    :menu              => [ 'true', 'false' ],
    :quality           => [ 'autohigh', 'low', 'autolow', 'medium', 'high', 'best' ],
    :scale             => [ 'default', 'noorder', 'exactfit' ],
    :salign            => [ 'tl', 'tr', 'bl', 'br', 'l', 'r', 't', 'b' ],
    :wmode             => [ 'window', 'opaque', 'transparent' ],
    :bgcolor           => /#[0-9a-fA-F]{6,6}/, # Must match #RRGGBB hexadecimal color
    :swliveconnect     => [ 'false', 'true' ],
    :devicefont        => [ 'true', 'false' ],
    :seamlesstabbing   => [ 'true', 'false' ],
    :allowfullscreen   => [ 'true', 'false' ],
    :allowlinks        => [ 'all', 'internal' ],
    :allowscriptaccess => [ 'sameDomain', 'never', 'always' ],
    :flashvars         => nil,
    :base              => nil
  }
  OPTIONAL_ATTRIBUTES = OPTIONAL_ATTRIBUTES_POSSIBLE_VALUES.keys

  def swf_object options = {}, &block
    apply_swf_object_option_transformations!(options)
    ensure_required_options!(options)
    add_default_options!(options)

    js = swf_object_js(url, options)

    if block_given?
      content = capture(&block)
      content = content_tag(:div, content, :id => options[:id])
      concat(content, block.binding)
      concat(js, block.binding)
    else
      (options[:alt] ? content_tag(:div, options[:alt], :id => options[:id]) : '') + 
      js
    end

  end

  def apply_swf_object_option_transformations! options
    options[:width], options[:height] = options[:size].split('x') if options[:size]

    if true == options[:alt]
      options[:alt] = %{This website requires #{link_to('Flash player', 'http://www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash')} #{options[:version]} or higher.}
    end
  end

  def add_default_options! options
    if options.has_key?(:allow_links)
      allow_links = options[:allow_links] ? 'all' : 'internal'
    else
      allow_links = 'all'
    end

    if options.has_key?(:allowscriptaccess)
      allow_script_access = options[:allowscriptaccess]
    else
      allow_script_access = 'sameDomain'
    end
  end

  # Generates just the javascript necessary to create a swfobject embed
  def swf_object_js options
    javascript_tag("swfobject.embedSWF(#{swf_object_args(options)});")
  end

  def swf_object_args options
    ( swf_object_string_arguments_from_options(options) +
      swf_object_hash_arguments_from_options(options)
    ).join(', ')
  end

  def swf_object_string_arguments_from_options options
    (REQUIRED_ARGUMENTS + OPTIONAL_ARGUMENTS).map do |arg|
      options[arg].to_s.to_json
    end
  end

  def swf_object_hash_arguments_from_options options
    HASH_ARGUMENTS.map do |arg|
      hash = options[arg] || {}
      if :flashvars == arg  # swfobject expects you to url encode flashvars values
        hash = Hash[*hash.inject([]) {|m,(k,v)| m << k << url_encode(v) }]
      end
      hash.to_json
    end
  end

  def ensure_required_options! options
    missing_arguments = REQUIRED_ARGUMENTS - options.keys
    unless missing_arguments.empty?
      raise ArgumentError, "Missing required SWFObject arguments: #{missing_arguments.join(', ')}"
    end
  end

end