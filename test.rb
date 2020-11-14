require 'marc/msgpack'
require 'json'
require 'benchmark'
require 'nokogiri'

sample = MARC::Reader.new(ARGF).first(5000).to_a

io = StringIO.new
Benchmark.bm do |x|
  x.report('msgpack out') do
    io = StringIO.new
    writer = MARC::Msgpack::Writer.new(io, compression_threshold: 1024)
    sample.each { |r| writer.write(r) }
    writer.close
  end
  puts "msgpack\t#{io.string.bytesize} bytes"

  x.report('msgpack in') do
    io.rewind
    out_rec = MARC::Msgpack::Reader.new(io).each.to_a
  end

  x.report('marc out') do
    io = StringIO.new
    writer = MARC::Writer.new(io)
    sample.each { |r| writer.write(r) }
  end
  puts "marc\t#{io.string.bytesize} bytes"

  x.report('marc in') do
    io.rewind
    out_rec = MARC::Reader.new(io).each.to_a
  end

  # x.report('xml out') do
  #   io = StringIO.new
  #   writer = MARC::XMLWriter.new(io)
  #   sample.each { |r| writer.write(r) }
  #   io.write("</collection>")
  # end
  # puts "xml\t#{io.string.bytesize} bytes"
  #
  # x.report('xml in') do
  #   io.rewind
  #   out_rec = MARC::XMLReader.new(io, parser: 'nokogiri').each.to_a
  # end
end

puts
puts

r = sample.sample(10).each do |r|
  puts r

  puts "=> format\tsize\tcompr"
  puts "   msgpack\t#{MARC::Msgpack::Writer.encode(r).bytesize}"
  puts "   marc\t#{r.to_marc.bytesize}"
  puts "   json\t#{r.to_marchash.to_json.bytesize}"
  puts "   xml\t#{r.to_xml.to_s.bytesize}"

  puts "   marc\t#{Zlib::Deflate.deflate(r.to_marc).bytesize}\tdeflate"
  puts "   json\t#{Zlib::Deflate.deflate(r.to_marchash.to_json).bytesize}\tdeflate"
  puts "   xml\t#{Zlib::Deflate.deflate(r.to_xml.to_s).bytesize}\tdeflate"
end
