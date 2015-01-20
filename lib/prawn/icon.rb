# encoding: utf-8
#
# icon.rb: Prawn icon functionality.
#
# Copyright October 2014, Jesse Doyle. All rights reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'prawn'
require_relative 'icon/font_data'
require_relative 'icon/parser'

module Prawn
  module Errors
    # Error raised when an icon glyph is not found
    #
    IconNotFound = Class.new(StandardError)

    # Error raised when an icon key is not provided
    #
    IconKeyEmpty = Class.new(StandardError)
  end

  # Easy icon font usage within Prawn. Currently
  # supported icon fonts include: FontAwesome,
  # Zurb Foundicons, and GitHub Octicons.
  #
  # = Icon Keys
  #
  # Icon keys must be supplied to most +Prawn::Icon+
  # methods. Keys map directly to a unicode character
  # within the font that produces a given icon. As a
  # rule, included icon keys should match the keys from
  # the font provider. The icon key mapping is specified
  # in the font's +legend_file+, which is a +YAML+ file
  # located in Prawn::Icon::FONTDIR/font/font.yml.
  #
  # Prawn::Icon::
  #   Houses the methods and interfaces necessary for
  #   rendering icons to the Prawn::Document.
  #
  # Prawn::Icon::FontData::
  #   Used to store various information about an icon font,
  #   including the key-to-unicode mapping information.
  #   Also houses methods to cache and lazily load the
  #   requested font data on a document basis.
  #
  # Prawn::Icon::Parser::
  #   Used to initially parse icons that are used with the
  #   inline_format: true option. The input string is parsed
  #   once for <icon></icon> tags, then the output is provided
  #   to Prawn's internal formatted text parser.
  #
  class Icon
    FONTDIR = File.join \
      File.expand_path('../../..', __FILE__), 'fonts'

    module Interface
      # Set up and draw an icon on this document. This
      # method operates much like +Prawn::Text::Box+.
      #
      # == Parameters:
      # key::
      #   Contains the key to a particular icon within
      #   a font family. If :inline_format is true,
      #   then key may contain formatted text marked
      #   with <icon></icon> tags and any tag supported
      #   by Prawn's parser.
      #
      # opts::
      #   A hash of options that may be supplied to
      #   the underlying +text+ method call.
      #
      # == Examples:
      #   pdf.icon 'fa-beer'
      #   pdf.icon '<icon color="0099FF">fa-arrows</icon>',
      #   inline_format: true
      #
      def icon(key, opts = {})
        i = make_icon(key, opts)
        i.render
        i
      end

      # Initialize a new icon object, but do
      # not render it to the document.
      #
      # == Parameters:
      # key::
      #   Contains the key to a particular icon within
      #   a font family. If :inline_format is true,
      #   then key may contain formatted text marked
      #   with <icon></icon> tags and any tag supported
      #   by Prawn's parser.
      #
      # opts::
      #   A hash of options that may be supplied to
      #   the underlying text method call.
      #
      def make_icon(key, opts = {})
        if opts[:inline_format]
          inline_icon(key, opts)
        else
          Icon.new(key, self, opts)
        end
      end

      # Initialize a new formatted text box containing
      # icon information, but don't render it to the
      # document.
      #
      # == Parameters:
      # text::
      #   Input text to be parsed initially for <icon>
      #   tags, then passed to Prawn's formatted text
      #   parser.
      #
      # opts::
      #   A hash of options that may be supplied to the
      #   underlying text call.
      #
      def inline_icon(text, opts = {})
        parsed    = Icon::Parser.format(self, text)
        content   = Text::Formatted::Parser.format(parsed)
        opts.merge!(inline_format: true, document: self)
        Text::Formatted::Box.new(content, opts)
      end
    end

    attr_reader :set, :unicode

    def initialize(key, document, opts = {})
      @pdf     = document
      @set     = opts[:set] ||
                 FontData.specifier_from_key(key)
      @data    = FontData.load(document, @set)
      @key     = strip_specifier_from_key(key)
      @unicode = @data.unicode(@key)
      @options = opts
    end

    def render
      @pdf.font(@data.path) do
        @pdf.text @unicode, @options
      end
    end

    private

    def strip_specifier_from_key(key)
      reg = Regexp.new "#{@data.specifier}-"
      key.sub(reg, '') # Only one specifier
    end
  end
end

Prawn::Document.extensions << Prawn::Icon::Interface
