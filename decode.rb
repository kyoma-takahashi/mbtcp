#!/usr/bin/ruby

# https://github.com/kyoma-takahashi/tklazyrtsp/blob/master/decode.rb

IN = $stdin
OUT = $stdout

DELIMITER = ' '

TIME_T_LENGTH = 8
LONG_LENGTH = 8
TIME_LENGTH = (TIME_T_LENGTH + LONG_LENGTH) * 3
TIME_UNPACK = 'Q6'
TIME_PRINTF = (['%19d', '%9d'] * 3).flatten.join(DELIMITER)

LENGTH_LENGTH = 2

DATA_LENGTH = 244
UNPACK = 'seeeeeeeeeeeeeeebeebeebbbbbbbbbbbebbbseeeeeeeeeeeeeeeeeeeeeee'.
  gsub('x','x4').gsub('e','e').gsub('b','b16b8b8').gsub('s','b16v')
  # e <=> g; s <=> S, n, v; b <=> B
PRINTF = UNPACK.
  gsub(/x\d*/, '').gsub(/[eg]/,"#{DELIMITER}%+.8e").gsub(/[sSnv]/,"#{DELIMITER}%+6d").gsub(/[bB]\d*/, "#{DELIMITER}%s")

def swap_2bytes(bytes)
  new = ''
  until bytes.empty?
    new << bytes[2,2]
    new << bytes[0,2]
    bytes = bytes[4, bytes.length - 4]
  end
  new
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
    OUT.printf(PRINTF, *swap_2bytes(data_b).unpack(UNPACK))
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
