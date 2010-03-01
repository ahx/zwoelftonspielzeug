# TODO Das läuft wie so Lochkarten-Computer, wo man vorne immer neue Lochkarten (class Karte)
# auf ein Band legt, die dann alle x Takte (time_in_beats) verarbeitet werden
# TODO Quantisierung: Eine neue Karte wird nur bei % n Schägen / Takten verarbeitet!
# TODO So schnell wie möglich fertig werden!

require 'thread'

 queue = Queue.new

 consumer = Thread.new do
   loop do
     value = queue.pop
     sleep 1
     puts "consumed #{value}"
   end
 end


# producer = Thread.new do
  loop do
    value = gets
    queue << value
    puts "#{value} produced"
  end
# end
# producer.join
