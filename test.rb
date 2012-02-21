require "em-synchrony"
require "em-synchrony/em-http"
require "em-synchrony/fiber_iterator"

t = Time.now
EM.synchrony do
  EM.synchrony do
    @result = 1
    EM::Synchrony.sleep(3)
  end
  EM::Synchrony.sleep(1)
  EM.stop
  p @result
end
p Time.now-t

EM.synchrony do
  @i = 0
  @workers = 0
  @concurrency = 1
  @active = []
  EM::Synchrony.add_periodic_timer(3) do
    if @concurrency > @workers
      
      puts "tick"
      puts "job"
      Fiber.new{ EM::Synchrony.sleep(4); puts "I am done"; @workers -= 1; EM.next_tick { p "wait" } }.resume
      @workers += 1
    end
  end
end


require './safe'
EventMachine::Synchrony::Safe.new([1,2,3,4], 3, 5) do |i|
  p i
end.start