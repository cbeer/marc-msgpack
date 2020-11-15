require 'marc/msgpack'
require 'json'
require 'benchmark'
require 'nokogiri'

# io = File.open('/Users/cabeer/tmp/marc.msgpack', 'w')
# writer = MARC::Msgpack::Writer.new(io, compression_threshold: 1024)
# i = 0
# MARC::Reader.new(ARGF).each { |r| i+= 1; writer.write(r) }
# writer.close
# io.close
# puts "msgpack\t #{i} records"
# exit 0

sample = MARC::Reader.new(ARGF).first(10000).to_a

io = StringIO.new
Benchmark.bm do |x|
  x.report('msgpack out') do
    io = StringIO.new
    writer = MARC::Msgpack::Writer.new(io, compression_threshold: 1024)
    sample.each { |r| writer.write(r) }
    writer.close
  end
  puts "msgpack\t#{io.string.bytesize} bytes"
  puts "msgpack\t#{Zlib::Deflate.deflate(io.string).bytesize} bytes (deflate)"

  x.report('msgpack in') do
    io.rewind
    out_rec = MARC::Msgpack::Reader.new(io).each.to_a
  end

  puts '---------'

  x.report('marc out') do
    io = StringIO.new
    writer = MARC::Writer.new(io)
    sample.each { |r| writer.write(r) }
  end
  puts "marc\t#{io.string.bytesize} bytes"
  puts "marc\t#{Zlib::Deflate.deflate(io.string).bytesize} bytes (deflate)"

  x.report('marc in') do
    io.rewind
    out_rec = MARC::Reader.new(io).each.to_a
  end

  puts '---------'

  x.report('json out') do
    io = StringIO.new
    sample.each { |r| io.puts(r.to_marchash.to_json) }
  end
  puts "json\t#{io.string.bytesize} bytes"
  puts "json\t#{Zlib::Deflate.deflate(io.string).bytesize} bytes (deflate)"

  x.report('json in') do
    io.rewind
    out_rec = io.each_line.map { |l| MARC::Record.new_from_marchash(JSON.parse(l)) }.to_a
  end

  # x.report('xml out') do
  #   io = StringIO.new
  #   writer = MARC::XMLWriter.new(io)
  #   sample.each { |r| writer.write(r) }
  #   io.write("</collection>")
  # end
  # puts "xml\t#{io.string.bytesize} bytes"
  # puts "xml\t#{Zlib::Deflate.deflate(io.string).bytesize} bytes (deflate)"
  #
  # x.report('xml in') do
  #   io.rewind
  #   out_rec = MARC::XMLReader.new(io, parser: 'nokogiri').each.to_a
  # end
end

exit
puts
puts

r = sample.sample(10).each do |r|
  puts r

  puts "=> format\tsize\tcompr"
  puts "   msgpack\t#{MARC::Msgpack::Writer.encode(r).bytesize}"
  puts "   marc\t#{r.to_marc.bytesize}"
  puts "   json\t#{r.to_marchash.to_json.bytesize}"
  puts "   xml\t#{r.to_xml.to_s.bytesize}"

  puts "   msgpack\t#{Zlib::Deflate.deflate(MARC::Msgpack::Writer.encode(r)).bytesize}\tdeflate"
  puts "   marc\t#{Zlib::Deflate.deflate(r.to_marc).bytesize}\tdeflate"
  puts "   json\t#{Zlib::Deflate.deflate(r.to_marchash.to_json).bytesize}\tdeflate"
  puts "   xml\t#{Zlib::Deflate.deflate(r.to_xml.to_s).bytesize}\tdeflate"
end
