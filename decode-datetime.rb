#!/usr/bin/ruby

require 'csv'
require 'time'

IN = $stdin
OUT = $stdout

DELIMITER = ' '

def process(row)
  timer = row.shift.to_i + Rational(row.shift.to_i, 1_000_000_000)
  raw = row.shift.to_i + Rational(row.shift.to_i, 1_000_000_000)
  real = Time.at(row.shift.to_i) + Rational(row.shift.to_i, 1_000_000_000)
  row.unshift(real.iso8601(9))
  row
end

case RUBY_VERSION
when '1.8.7'
  IN.each do |line|
    OUT.puts process(line.chomp.split(DELIMITER)).join(DELIMITER)
  end
when '2.3.1'
  CSV.filter(IN, OUT, :col_sep => DELIMITER, :headers => false) do |row|
    process(row)
  end
else
  warn "#{RUBY_VERSION} not supported"
end
