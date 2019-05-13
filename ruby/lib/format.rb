class String
  def fixed_width(width = 64)
    return self + (" " * (width - self.size)) if self.size < width

    self[0, width - 3].chomp + "..."
  end

  def red
    return "\e[31m" + self + "\e[39m"
  end

  def green
    return "\e[32m" + self + "\e[39m"
  end

  def blue
    return "\e[34m" + self + "\e[39m"
  end

  def magenta
    return "\e[35m" + self + "\e[39m"
  end

  def cyan
    return "\e[36m" + self + "\e[39m"
  end

  def white
    return "\e[37m" + self + "\e[39m"
  end


  def bg_black
    return "\e[40m" + self + "\e[49m"
  end

  def bg_yellow
    return "\e[43m" + self + "\e[49m"
  end

  def bold
    return "\e[1m" + self + "\e[0m"
  end

  def underline
    return "\e[4m" + self + "\e[0m"
  end

  def blink
    return "\e[5m" + self + "\e[0m"
  end
end