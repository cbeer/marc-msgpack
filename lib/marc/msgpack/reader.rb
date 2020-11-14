module MARC
  module Msgpack
    class Reader
      include Enumerable

      def initialize(file)
        @file = file
      end

      def unpacker
        @unpacker ||= MessagePack::Unpacker.new(@file).tap do |u|
          u.register_type(0x01, CompressedString, :from_msgpack_ext)
          u.register_type(0x02, TruncatedLeader, :from_msgpack_ext)
        end
      end

      def each
        return to_enum(:each) unless block_given?

        until @file.eof?
          yield read_one
        end
      end

      def read_one
        header = unpacker.read

        raise(MARC::Msgpack::Error, 'not our marc') unless header['type'] == 'marc' && header.dig('version', 0) == 1

        r = MARC::Record.new
        r.leader = header['leader']

        unpacker.read.each do |f|
          if f.length == 2
            r << MARC::ControlField.new(*f)
          else
            r << MARC::DataField.new(f[0], f[1], f[2], *f[3].each_slice(2).to_a)
          end
        end

        r
      end
    end
  end
end
