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


## Performance

For this test, I'm using a 1000,000 MARC record data set and reading + writing data to an in-memory StringIO (see test.rb).

| what | user | system | total | real | % of MARC21|
|---|---:|---:|---:|---:|---:|
| marc write    | 17.481686 | 0.299942 | 17.781628 | ( 17.789118) | 100% |
| json write    |  7.429433 | 0.071398 |  7.500831 | (  7.503990) |  42% |
| msgpack write |  7.604279 | 0.133938 |  7.738217 | (  7.740787) |  43% |
| marc read    |  23.358852 | 0.088938 |  23.447790 | ( 23.455563) | 100% |
| json read    |  13.268984 | 0.016315 |  13.285299 | ( 13.289286) |  57% |
| msgpack read |  12.729819 | 0.263409 |  12.993228 | ( 13.001891) |  55% |

----

| what | uncompressed | % | w/ deflate | % |
|---|---:|---:|---:|---:|
| marc    | 87.4 MB | 100% | 26.1 MB | 30% |
| json    | 119 MB  | 135% | 22.8 MB | 26% |
| msgpack | 79.1 MB |  90% | 22.7 MB | 26% |

---

So, should you use this? 🤷‍♂️

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cbeer/marc-msgpack. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cbeer/marc-msgpack/blob/master/CODE_OF_CONDUCT.md).


## Code of Conduct

Everyone interacting in the MARC::Msgpack project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cbeer/marc-msgpack/blob/master/CODE_OF_CONDUCT.md).
