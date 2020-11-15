module MARC
  module Msgpack
    class Writer
      attr_reader :compression_threshold

      def initialize(file, compression_threshold: 1024)
        @file = file
        @compression_threshold = compression_threshold
      end

      def packer
        @packer ||= MARC::Msgpack.factory.packer(@file)
      end

      def write(record)
        packer.write_array_header(2)

        packer.write(['marc', 0b01, TruncatedLeader.new(record.leader)])
        packer.write_array_header(record.fields.length)
        record.fields.each do |field|
          if field.is_a? MARC::ControlField
            packer.write([field.tag, field.value])
          else
            indicators = if field.indicator1 == ' ' && field.indicator2 == ' '
              []
            else
              [
                field.indicator1 == ' ' ? nil : field.indicator1,
                field.indicator2 == ' ' ? nil : field.indicator2
              ]
            end
            subfields = field.subfields.flat_map { |s| [s.code, compression_threshold > 0 ? to_msgpack_string(s.value) : s.value] }
            packer.write([field.tag, indicators, subfields])
          end
        end
      end

      def close
        @packer.flush
      end

      def self.encode(record, **args)
        io = StringIO.new

        writer = new(io, **args)
        writer.write(record)
        writer.close

        io.string
      end

      private

      def to_msgpack_string(s)
        return s if s.bytesize < compression_threshold

        CompressedString.new(s)
      end
    end
  end
end
