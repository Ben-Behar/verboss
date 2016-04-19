# Verboss

Verboss is a lightweight gem that is designed to assist developers in organizing and understanding terminal output.
Verboss focuses on understanding encapsulation.  By using the methods "quietly" and "loudly", code can be easily tracked during runtime through the terminal.  For example:


    task :derp do
      def method args
        puts "one argument: #{args}"
      end
  
      Verbose.loudly "Doing a counting sort of thing" do
        (1..10).each do |num|
          method(num)
          $stderr.puts "error!"
        end
      end
    end

outputs the following:
  
    / Doing a counting sort of thing                              \
    | one argument: 1
    $ errrr?
    | one argument: 2
    $ errrr?
    | one argument: 3
    $ errrr?
    | one argument: 4
    \ _ _ _ _ _ _ _ _ _ _ _ _ _ _ DONE in 0.006s     _ _ _ _ _ _ _ /

Verboss will capture everything that you have included in the block provided and format it for easier identification.
It will also provide a rough benchmark estimate, for convenience.
Both $stderr and $stdout will be captured and formatted for trivial distinction.

But say, you have a method that is filling up the screen.  The proper thing to do would be to fix the method, but let's be honest, you don't want to do that.
Instead use "Verbose.quietly 'doing the method'":

    ...  
    Verbose.quietly "Doing a counting sort of thing" do
      (1..10).each do |num|
        method(num)
        $stderr.puts "errrr?"
      end
    end
    ...
Which produces:

    Doing a counting sort of thing                             DONE in 0.002s

This time there is no noise or distraction.  

