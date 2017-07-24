#!/usr/bin/ruby

require 'csv'
require 'time'

IN = $stdin
OUT = $stdout

DELIMITER = ' '

CSV.filter(IN, OUT, :col_sep => DELIMITER, :headers => false) do |row|
  timer = row.shift.to_i + Rational(row.shift.to_i, 1_000_000_000)
  raw = row.shift.to_i + Rational(row.shift.to_i, 1_000_000_000)
  real = Time.at(row.shift.to_i) + Rational(row.shift.to_i, 1_000_000_000)
  row.unshift(real.iso8601(9))
  row
end
