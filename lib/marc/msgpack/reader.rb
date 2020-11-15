module MARC
  module Msgpack
    class Reader
      include Enumerable

      def initialize(file, exception_handler: nil)
        @file = file
        @exception_handler = exception_handler
      end

      def unpacker
        @unpacker ||= MARC::Msgpack.factory.unpacker(@file)
      end

      def each(&block)
        return to_enum(:each) unless block_given?

        unpacker.each do |obj|
          yield read_one(*obj)
        rescue => e
          raise e unless @exception_handler

          @exception_handler.call(self, e, block)
        end
      end

      private

      def read_one(header, fields)
        type, version, leader = header
        raise(MARC::Msgpack::Error, "expected type=marc, v=1, got '#{header}'") unless type == 'marc' && version == 0b01

        r = MARC::Record.new
        r.leader = leader

        fields.each do |(tag, *values)|
          if values.length == 1
            r << MARC::ControlField.new(tag, *values)
          else
            indicators, subfields = values
            r << MARC::DataField.new(tag, indicators[0], indicators[1], *subfields.each_slice(2).to_a)
          end
        end

        r
      end
    end
  end
end
