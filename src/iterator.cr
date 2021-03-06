module Iterator(T)
  class Stop
    INSTANCE = new
  end

  def stop
    Stop::INSTANCE
  end

  include Enumerable(T)

  def map(&func : T -> U)
    MapIterator(typeof(self), T, U).new(self, func)
  end

  def select(&func : T -> _)
    SelectIterator(typeof(self), T).new(self, func)
  end

  def reject(&func : T -> _)
    RejectIterator(typeof(self), T).new(self, func)
  end

  def take(n)
    TakeIterator(typeof(self), T).new(self, n)
  end

  def skip(n)
    SkipIterator(typeof(self), T).new(self, n)
  end

  def zip(other : Iterator(U))
    ZipIterator(typeof(self), typeof(other), T, U).new(self, other)
  end

  def cycle
    CycleIterator(typeof(self), T).new(self)
  end

  def with_index
    WithIndexIterator(typeof(self), T).new(self)
  end

  def each
    while true
      value = self.next
      break if value.is_a?(Stop)
      yield value
    end
  end
end

class Array
  def iterator
    ArrayIterator.new(self)
  end
end

class ArrayIterator(T)
  include Iterator(T)

  def initialize(@array : Array(T), @index = 0)
  end

  def next
    if @index >= @array.length
      return stop
    end

    value = @array.buffer[@index]
    @index += 1
    value
  end

  def clone
    ArrayIterator(T).new(@array, @index)
  end
end

struct Range
  def iterator
    RangeIterator.new(self)
  end
end

class RangeIterator(B, E)
  include Iterator(B)

  def initialize(@range : Range(B, E), @current = range.begin, @reached_end = false)
  end

  def next
    if @reached_end
      return stop
    end

    if @current == @range.end
      @reached_end = true

      if @range.excludes_end?
        return stop
      else
        return @current
      end
    else
      value = @current
      @current = @current.succ
      value
    end
  end

  def clone
    RangeIterator(B, E).new(@range, @current, @reached_end)
  end
end

struct MapIterator(I, T, U)
  include Iterator(U)

  def initialize(@iter : Iterator(T), @func : T -> U)
  end

  def next
    value = @iter.next
    return stop if value.is_a?(Stop)
    @func.call(value)
  end

  def clone
    MapIterator.new(@iter.clone, @func)
  end
end

struct SelectIterator(I, T)
  include Iterator(T)

  def initialize(@iter : Iterator(T), @func : T -> B)
  end

  def next
    while true
      value = @iter.next
      return stop if value.is_a?(Stop)

      if @func.call(value)
        return value
      end
    end
  end

  def clone
    SelectIterator(I, T).new(@iter.clone, @func)
  end
end

struct RejectIterator(I, T)
  include Iterator(T)

  def initialize(@iter : Iterator(T), @func : T -> B)
  end

  def next
    while true
      value = @iter.next
      return stop if value.is_a?(Stop)

      unless @func.call(value)
        return value
      end
    end
  end

  def clone
    RejectIterator(I, T).new(@iter.clone, @func)
  end
end

class TakeIterator(I, T)
  include Iterator(T)

  def initialize(@iter : Iterator(T), @n : Int)
  end

  def next
    if @n > 0
      value = @iter.next
      return stop if value.is_a?(Stop)

      @n -= 1
      value
    else
      stop
    end
  end

  def clone
    TakeIterator(I, T).new(@iter.clone, @n)
  end
end

class SkipIterator(I, T)
  include Iterator(T)

  def initialize(@iter : Iterator(T), @n : Int)
  end

  def next
    while @n > 0
      @iter.next
      @n -= 1
    end
    @iter.next
  end

  def clone
    SkipIterator(I, T).new(@iter.clone, @n)
  end
end

struct ZipIterator(I1, I2, T1, T2)
  include Iterator({T1, T2})

  def initialize(@iter1, @iter2)
  end

  def next
    v1 = @iter1.next
    return stop if v1.is_a?(Stop)

    v2 = @iter2.next
    return stop if v2.is_a?(Stop)

    {v1, v2}
  end

  def clone
    ZipIterator(I1, I2, T1, T2).new(@iter1.clone, @iter2.clone)
  end
end

class CycleIterator(I, T)
  include Iterator(T)

  def initialize(@iterator : Iterator(T))
    @original = @iterator.clone
  end

  def next
    value = @iterator.next
    if value.is_a?(Stop)
      @iterator = @original.clone
      @iterator.next
    else
      value
    end
  end
end

class WithIndexIterator(I, T)
  include Iterator({T, Int32})

  def initialize(@iterator : Iterator(T), @index = 0)
  end

  def next
    v = @iterator.next
    return stop if v.is_a?(Stop)

    value = {v, @index}
    @index += 1
    value
  end

  def clone
    WithIndexIterator(I, T).new(@iterator.clone, @index)
  end
end

