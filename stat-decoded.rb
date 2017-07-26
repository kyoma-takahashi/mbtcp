#!/usr/bin/ruby

case RUBY_VERSION
when '1.8.7'
  require 'rational'
when '2.3.1'
  # ok
else
  warn "#{RUBY_VERSION} not supported"
end

class Counter
  attr_reader :counts, :total_class
  def initialize
    @counts = {}
    @total_class = nil;
  end
  def add(cls)
    @counts[cls] ||= 0
    @counts[cls] += 1
    if @total_class
      @total_class += cls
    else
      @total_class = cls
    end
  end
  def total
    @counts.values.inject(0) {|r,i| r + i}
  end
end

widths = Counter.new

counts = []

ARGV.each do |datfile|

  prev = nil

  IO.foreach(datfile) do |line|
    widths.add(line.chomp.length)
    vals = line.sub(/^ +/, '').split(/ +/)[0, 6]
    now = []
    until vals.empty?
      now << vals.shift.to_i + Rational(vals.shift.to_i, 1_000_000_000)
    end
    if prev
      now.each_index do |i|
        counts[i] ||= Counter.new
        counts[i].add(now[i] - prev[i])
      end
    end
    prev = now
  end

end

[widths, counts].flatten.each do |c|
  cs = c.counts
  tc = 0
  tcv = 0
  cs.keys.sort.each do |cls|
    print cls.to_f
    tc += cs[cls]
    print ' '
    print (1 - tcv / c.total_class).to_f
    puts
    tcv += cs[cls] * cls
  end
  puts c.total
  puts c.total_class.to_f
  puts
  unless c.total == tc
    warn "Maybe a bug: Total count mismatch. #{c.total} != #{tc}"
  end
  unless c.total_class == tcv
    warn "Maybe a bug: Total count x class mismatch. #{c.total_class} != #{tcv}"
  end
end
