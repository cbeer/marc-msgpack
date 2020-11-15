require "marc/msgpack/version"
require 'msgpack'
require 'zlib'
require 'stringio'
require 'marc'
require 'marc/msgpack/reader'
require 'marc/msgpack/writer'

module MARC
  module Msgpack
    class Error < StandardError; end

    class TruncatedLeader
      def initialize(leader)
        @leader = leader
      end

      def to_msgpack_ext
        "#{@leader[5..8]}#{@leader[17..19]}"
      end

      def self.from_msgpack_ext(str)
        "     #{str[0..3]}a22     #{str[4..7]}4500"
      end
    end

    class LazyDecompressedString < BasicObject
      undef_method :equal?

      def initialize(obj)
        @compressed_string = obj
      end

      def ==(other)
        return false if other.nil?

        string.send(:==, other)
      end

      def string
        @string ||= ::Zlib::Inflate.inflate(@compressed_string)
      end

      def method_missing(name, *args, &block)
        string.send(name, *args, &block)
      end

      def respond_to_missing?(name, include_private = false)
        ''.respond_to?(name, include_private)
      end

      # Let the projct object at least raise exceptions.
      def raise(*args)
        ::Object.send(:raise, *args)
      end
    end

    class CompressedString
      def initialize(string)
        @string = string
      end

      def to_msgpack_ext
        Zlib::Deflate.deflate(@string)
      end

      def self.from_msgpack_ext(obj)
        LazyDecompressedString.new(obj)
      end
    end

    def self.factory
      @factory ||= MessagePack::Factory.new.tap do |factory|
        factory.register_type(0x01, CompressedString, packer: :to_msgpack_ext, unpacker: :from_msgpack_ext)
        factory.register_type(0x02, TruncatedLeader, packer: :to_msgpack_ext, unpacker: :from_msgpack_ext)
      end
    end
  end
end
