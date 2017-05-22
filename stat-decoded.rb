#!/usr/bin/ruby

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

counts = []

prev = nil

while line = gets
  vals = line.sub(/^ +/, '').split(/ +/)[0, 6]
  now = []
  until vals.empty?
    now << vals.shift.to_i + Rational(vals.shift, 1_000_000_000)
  end
  if prev
    now.each_index do |i|
      counts[i] ||= Counter.new
      counts[i].add(now[i] - prev[i])
    end
  end
  prev = now
end

counts.each do |c|
  cs = c.counts
  tc = 0
  tcv = 0.0
  cs.keys.sort.each do |cls|
    print cls.to_f
    tc += cs[cls]
    tcv += cs[cls] * cls
    print ' '
    print tc
    print ' '
    print (1 - tcv / c.total_class).to_f
    puts
  end
  print ' '
  puts c.total
  puts
end
