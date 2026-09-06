# Aerodynamic lead-only comparison
# Plays one complete lead sequence with no other layers.

use_bpm 123

use_synth :zawa
use_synth_defaults attack: 0.05, sustain: 0.15, release: 0.125, amp: 0.55

phases = [
  [:d4, :fs3, :b3, :fs3],
  [:d4, :gs3, :b3, :gs3],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3],
  [:d4, :fs4, :b3, :fs4],
  [:d4, :gs4, :b3, :gs4],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3]
]

phases.each do |notes|
  4.times do
    notes.each do |pitch|
      play pitch
      sleep 0.25
    end
  end
end
