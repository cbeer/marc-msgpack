module MARC
  module Msgpack
    class Reader
      include Enumerable

      def initialize(file, exception_handler: nil)
        @file = file
        @exception_handler = exception_handler
      end

      def unpacker
        @unpacker ||= MessagePack::Unpacker.new(@file).tap do |u|
          u.register_type(0x01, CompressedString, :from_msgpack_ext)
          u.register_type(0x02, TruncatedLeader, :from_msgpack_ext)
        end
      end

      def each(&block)
        return to_enum(:each) unless block_given?

        until @file.eof?
          begin
            yield read_one
          rescue => e
            raise e unless @exception_handler

            @exception_handler.call(self, e, block)
          end
        end
      end

      def read_one
        header, fields = unpacker.read

        type, version, leader = header
        raise(MARC::Msgpack::Error, "expected is=marc, v=0b10, got '#{header}'") unless type == 'marc' && version == 0b01

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
