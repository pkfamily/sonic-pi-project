# Midnight Club
# Standalone Sonic Pi sketch

use_bpm 120

live_loop :drums do
  sample :bd_ada, amp: 1.6
  sleep 0.5
  sample :bd_ada, amp: 0.9
  sleep 0.5
  sample :sn_dub, amp: 1.2
  sleep 0.5
  sample :sn_dub, amp: 1.0
  sleep 0.5
end

live_loop :hats do
  8.times do
    sample :drum_cymbal_closed, amp: 0.28, finish: 0.08
    sleep 0.25
  end
end

live_loop :bass do
  use_synth :tb303
  notes = (ring :a2, :a2, :d2, :d2, :e2, :e2, :g2, :g2)
  8.times do |i|
    play notes[i], release: 0.22, cutoff: rrand(70, 105), res: 0.8, wave: 0
    sleep 0.5
  end
end

live_loop :guitar_stabs do
  use_synth :pluck
  chords = (ring chord(:a3, :minor), chord(:d3, :minor),
            chord(:e3, :minor), chord(:g3, :dom7))
  4.times do |i|
    play chords[i], release: 0.18, amp: 0.7
    sleep 1
    play chords[i], release: 0.12, amp: 0.45
    sleep 1
  end
end

live_loop :hook do
  use_synth :prophet
  play_pattern_timed [:a4, :c5, :e5, :g5, :e5, :c5],
                     [0.25, 0.25, 0.25, 0.5, 0.25, 0.5],
                     release: 0.12, cutoff: 90, amp: 0.28
  sleep 2
end
