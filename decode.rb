#!/usr/bin/ruby

# https://github.com/kyoma-takahashi/tklazyrtsp/blob/master/decode.rb

IN = $stdin
OUT = $stdout

DELIMITER = ' '

TIME_T_LENGTH = 8
LONG_LENGTH = 8
TIME_LENGTH = (TIME_T_LENGTH + LONG_LENGTH) * 3
TIME_UNPACK = case RUBY_VERSION
              when '1.8.7'
                'Q'
              when '2.3.1'
                'Q<'
              else
                warn 'Unknown whether or not unpack template "Q<" is supported'
                'Q<'
              end + '6'
TIME_PRINTF = (['%19d', '%9d'] * 3).flatten.join(DELIMITER)

LENGTH_LENGTH = 2

DATA_LENGTH = 244
UNPACK = 'seeeeeeeeeeeeeeebeebeebbbbbbbbbbbebbbseeeeeeeeeeeeeeeeeeeeeee'.
  gsub('x','x4').gsub('e','g').gsub('b','b8b24').gsub('s','nb16')
  # e <=> g; s <=> S, n, v; b <=> B
PRINTF = UNPACK.
  gsub(/x\d*/, '').gsub(/[eg]/,"#{DELIMITER}%+.8e").gsub(/[sSnv]/,"#{DELIMITER}%+6d").gsub(/[bB]\d*/, "#{DELIMITER}%s")

def swap_bytes(bytes)
  # for each two bytes, swap the former and the latter bytes
  bytes.unpack('v*').pack('n*')
end

def read_contents
  buffer = ''
  loop do
    return false unless length_b = IN.read(LENGTH_LENGTH)
    length = length_b.unpack('v').first
#     warn "Length:>#{length}<"
    break if 0 == length
    buffer << IN.read(length)
  end
  buffer
end

loop do

  break unless system_time = IN.read(TIME_LENGTH)
  OUT.printf(TIME_PRINTF, *system_time.unpack(TIME_UNPACK))

  break unless data_b = read_contents
#   warn "Read:>#{data_b.bytesize}<"

  if (DATA_LENGTH == data_b.bytesize)
    OUT.printf(PRINTF, *swap_bytes(data_b).unpack(UNPACK))
  else
    OUT.print DELIMITER
    OUT.print data_b.bytesize.to_s
    OUT.print DELIMITER
    # hex dump
    OUT.print data_b.unpack('H*').first
  end

  OUT.puts
  OUT.flush
end
