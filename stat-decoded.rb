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
  attr_reader :counts, :total_class_prerounded, :total_class

  def initialize(round_factor = nil)
    @round_factor = round_factor
    @counts = {}
    @total_class = nil
    @total_class_prerounded = nil
  end

  def round(cls)
    if @round_factor
      Rational((cls * @round_factor).ceil, @round_factor)
    else
      cls
    end
  end

  def add(cls)
    rounded = round(cls)
    @counts[rounded] ||= 0
    @counts[rounded] += 1
    @total_class ||= 0
    @total_class += rounded
    @total_class_prerounded ||= 0
    @total_class_prerounded += cls
  end

  def total
    @counts.values.inject(0) {|r,i| r + i}
  end
end

widths = Counter.new

PROGRESS_STEP = 100_000_000
progress_next = 0

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
        counts[i] ||= Counter.new(1_000_0)
        counts[i].add(now[i] - prev[i])
      end
    end
    prev = now

    if widths.total_class_prerounded > progress_next
      warn "#{Time.now.strftime('%FT%T%z')} #{widths.total_class_prerounded} #{datfile}"
      progress_next = widths.total_class_prerounded + PROGRESS_STEP
    end
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
  puts c.total_class_prerounded.to_f
  puts
  unless c.total == tc
    warn "Maybe a bug: Total count mismatch. #{c.total} != #{tc}"
  end
  unless c.total_class == tcv
    warn "Maybe a bug: Total count x class mismatch. #{c.total_class} != #{tcv}"
  end
end
