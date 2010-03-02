# encoding: UTF-8
# TODO Das läuft wie so Lochkarten-Computer, wo man vorne immer neue Lochkarten (class Karte)
# auf ein Band legt, die dann alle x Takte (time_in_beats) verarbeitet werden
# TODO Quantisierung: Eine neue Karte wird nur bei % n Schägen / Takten verarbeitet!
# TODO So schnell wie möglich fertig werden!

require 'thread'

class Automat
  attr :queue
  attr :run_loop
  
  def initialize
    @queue = Queue.new
  end
  
  def start
    @run_loop = Thread.new do
      loop do
        while !@queue.empty?
          puts "pop! #{@queue.pop}"
        end
      end
    end
  end

  def stop
    @run_loop.exit
  end
end

a = Automat.new
a.start
loop do
  a.queue << Time.now.to_s
  sleep 1
end