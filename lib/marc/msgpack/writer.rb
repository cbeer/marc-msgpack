module MARC
  module Msgpack
    class Writer
      attr_reader :compression_threshold

      def initialize(file, compression_threshold: 1024)
        @file = file
        @compression_threshold = compression_threshold
      end

      def packer
        @packer ||= MessagePack::Packer.new(@file).tap do |pk|
          pk.register_type(0x01, CompressedString, :to_msgpack_ext)
          pk.register_type(0x02, TruncatedLeader, :to_msgpack_ext)
        end
      end

      def write(record)
        packer.write(type: 'marc', version: [1, 0], leader: TruncatedLeader.new(record.leader))

        packer.write_array_header(record.fields.length)
        record.fields.each do |field|
          if field.is_a? MARC::ControlField
            packer.write(field.to_marchash)
          else
            tag, ind1, ind2, subfields = field.to_marchash
            subfields = subfields.flatten
            subfields = subfields.map { |x| to_msgpack_string(x) } if compression_threshold > 0
            packer.write([tag, ind1, ind2, subfields])
          end
        end
      end
      # close underlying filehandle

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
