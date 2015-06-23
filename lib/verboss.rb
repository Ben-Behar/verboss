##### Verbose Module####
 # allows concise method calls to organize and standardize terminal output
 # Verbose.doing organizes all output that occurs during its block
 # Verbose.quiet allows for all output to be silenced, displaying only the passed argument (if given)
 #
 # The last few methods: say, mention, yell, scream
 # These are intended to standardize the format of certain kinds of output by
 # level of importance
 # say     -> general information    -> normal font
 # mention -> important information  -> blue font
 # cheer   -> success was reached    -> green font
 # yell    -> problem was discovered -> red font
 # scream  -> even the heavens must know -> disgusting font
 #
module Verboss
  @@err_indent = "$ ".color(:magenta)
  @@out_indent = "| ".color(:magenta)
  @@root_stderr = $stderr
  @@root_stdout = $stdout

  @@temporary_options = {
    quiet:      false,
    no_logging: false
  }


  @@spinner = {
    on:    false,
    chars: %w[| / - \\],
    index: 0,
    delay: 0.5,
    debug_level: 0,
    thread: Thread.new {
      while @@spinner[:thread]
        Thread.stop unless @@spinner[:on]
        sleep @@spinner[:delay]
        c =  (@@spinner[:chars][ @@spinner[:index] = (@@spinner[:index] + 1) % @@spinner[:chars].length ] + "\b").color(:white).bright.background(:black)
        @@root_stdout.print c
      end
    }
  }

## FLAG METHODS
  def self.migrations? # helper used to determine if ActiveRecord::Migration.verbose should be true
    ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : false
  end

  def self.trace? # helper used to determine if stack traces should be displayed or not
    ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : false
  end

  def self.level arg = 1
    case ENV["VERBOSE"]
    when Numeric then arg <= ENV["VERBOSE"]
    when nil then false
    else
      true
    end
  end

## WAIT SPINNER ##
  def self.start_spinner
    @@spinner[:on] = true
    @@spinner[:thread].wakeup if @@spinner[:thread].status == "sleep"
  end

  def self.stop_spinner
    @@spinner[:on] = false
  end

  def self.wait_spinner options = {}
    @@spinner[:delay] = options[:fps] * 60 if options[:fps]
    @@spinner[:delay] = options[:delay] if options[:delay]
    Verbose.start_spinner
    yield
    Verbose.stop_spinner
  end


## MESSAGE CONSISTENCY METHODS

  def self.say *args
    args.each { |a| $stdout.puts a }
  end

  def self.mention *args
    args.each { |a| $stdout.puts "#{a.to_s.color(:blue)}" }
  end

  def self.cheer *args
    args.each { |a| $stdout.puts "#{a.to_s.color(:green)}" }
  end

  def self.yell *args
    args.each { |a| $stderr.puts "\n#{a.to_s.color(:red)}" }
  end

  def self.scream *args
    args.each { |a| $stderr.puts "\n#{a.to_s.color(:red).background(:yellow).underline.bright.blink}" }
  end


## IO CAPTURING/FORMATTING METHODS ## allow method invocations such as Verbose.quiet.no_logging to work as expected

  def self.option keyword=false
    case keyword
    when :loud        then @@temporary_options[:quiet] = false
    when :quiet       then @@temporary_options[:quiet] = true
    when :no_logging  then @@temporary_options[:no_logging] = true
    when :logging     then @@temporary_options[:no_logging] = false
    else
      return @@temporary_options # else return option hash
    end
    self # return self for chaining
  end

  def self.quietly description=nil # allows chaining unless a block is given
    return Verbose.option :quiet unless block_given? # if no block set 'quiet: true'

    if Verbose.option[:no_logging] # if no logging, then turn if off
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      ret = Verbose.quiet! description, &Proc.new

      ActiveRecord::Base.logger = old_logger
    else
      ret = Verbose.quiet! description, &Proc.new  # if logging is ok, log away
    end

    @@temporary_options = {}

    ret
  end

  def self.loudly description=nil
    return Verbose.option :loud unless block_given?

    if Verbose.option[:no_logging] # if no logging, then turn if off
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      ret = Verbose.loud! description, &Proc.new

      ActiveRecord::Base.logger = old_logger
    else
      ret = Verbose.loud! description, &Proc.new # if logging is ok, log away
    end

    @@temporary_options = {}
    ret
  end

  def self.logging description=nil
    return Verbose.option :logging unless block_given?

    if Verbose.option[:quiet]
      ret = Verbose.quiet! description, &Proc.new
    else
      ret = Verbose.loud!  description, &Proc.new
    end

    @@temporary_options = {}
    ret
  end

  def self.no_logging description=nil
    return Verbose.option :no_logging unless block_given?

    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    if Verbose.option[:quiet]
      ret = Verbose.quiet! description, &Proc.new
    else
      ret = Verbose.loud!  description, &Proc.new
    end
    ActiveRecord::Base.logger = old_logger
    @@temporary_options = {}
    ret
  end

##


  def self.loud! description="NO DESCRIPTION" # captures output from inside of the provided block and outputs them formatted
    start_time = Time.now
    # save a reference to the two IO's
    out = $stdout
    err = $stderr
    out.puts "/ #{description.to_s.widthize(WIDTH-4).bright} \\".color(:magenta)
    begin # IO and Thread stuffs
      Verbose.start_spinner
      read_out, write_out = IO.pipe
      read_err, write_err = IO.pipe
      $stderr    = write_err
      $stdout    = write_out
      out_thread = Thread.new { out.print @@out_indent + read_out.gets("\n") until read_out.eof? }
      err_thread = Thread.new { err.print @@err_indent + read_err.gets("\n") until read_err.eof? }
      ret = yield
    rescue Exception => msg
      err.puts "# #{description.to_s.widthize(WIDTH-4)} FAIL ".bright.color(:red)
      raise msg
    ensure # whether or not the block fails close the pipes
      write_out.close
      write_err.close
      out_thread.join
      err_thread.join
      Verbose.stop_spinner
    end
    out.puts "\\ #{"_ " * 14}".color(:magenta) + "DONE".color(:green).bright + " in #{Time.now - start_time}s".widthize(14).color(:cyan) + " _ _ _ _ _ _ _ /".color(:magenta)
    return ret
  ensure # both IO's go back the way they were found
    $stderr = err
    $stdout = out
  end

  def self.quiet! description = false
    start_time = Time.now
    # save a reference to the two IO's
    out = $stdout
    err = $stderr
    out.puts description.to_s.widthize(WIDTH-10).bright.color(:magenta)  + "  ... ".bright.color(:blue) if description
    begin # IO and Thread stuffs
      Verbose.start_spinner
      $stderr = StringIO.new
      $stdout = StringIO.new
      ret = yield
    rescue Exception => msg
      err.print "\e[1A" if description
      err.puts "# #{description.to_s.widthize(WIDTH-6)}".color(:red) + "FAIL".bright.color(:red)
      raise msg
    ensure
      Verbose.stop_spinner
    end
    if description
      out.print "\e[1A"
      out.puts description.to_s.widthize(WIDTH-8).bright.color(:magenta) + "DONE".color(:green).bright + " in #{Time.now - start_time}s".widthize(14).color(:cyan)
    end
    return ret
  ensure # both IO's go back the way they were found
    $stderr = err
    $stdout = out
  end


end

