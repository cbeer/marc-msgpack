# MARC::Msgpack

Encode MARC records using msgpack.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'marc-msgpack'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install marc-msgpack

## Usage

Writing:
```
# given:
# `io`, an io-like object (e.g. a File, StringIO, etc)
# `marc_records`, an enumerable of MARC::Record instances:
writer = MARC::Msgpack::Writer.new(io, compression_threshold: 1024)
marc_records.each { |r| writer.write(r) }
writer.close
```

Reading:
```
# given:
# `io`, an io-like object (e.g. a File, StringIO, etc)
MARC::Msgpack::Reader.new(io).each.to_a
```

## msgpack profile

This profile defines 2 msgpack extensions:

- `0x01` | containing a DEFLATE compressed string
- `0x02` | containing bytes 5-8 and 17-19 of the MARC leader (because e.g. lengths, offsets, and counts are unnecessary)

A MARC record encoded in msgpack is a 2-element array consisting of:
- a header, containing a 3-element array of:
    - the type: 'marc'
    - the version: 1
    - leader: the MARC leader, expressed either as a 24-byte string (as in MARC21) or extension type `0x02` which omits unnecessary information

- and an array of field values, expressed either as:
   - a 2-element array: the MARC tag and field value (e.g. for control fields)
   - a 4-element array: the MARC tag, an array of indicators, and an array of subfields:
       - indicators may be an empty array (meaning, no data in either indicator) or e.g. a 2-element array
       - subfields are an "flattened" array; each pair of 2 values are a subfield code and value.

Note: Subfield values may contain msgpack strings or may be encoded with extension type `0x01`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cbeer/marc-msgpack. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cbeer/marc-msgpack/blob/master/CODE_OF_CONDUCT.md).


## Code of Conduct

Everyone interacting in the MARC::Msgpack project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cbeer/marc-msgpack/blob/master/CODE_OF_CONDUCT.md).
