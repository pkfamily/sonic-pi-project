# Aerodynamic layered built-in-synth lead study
#
# Option 2 experiment: thicken the existing :zawa lead with a restrained
# upper sine and a quiet, lightly detuned dsaw layer. The note order and
# mixed-register voicing match studies/lead_only.rb.

use_bpm 123

define :layered_lead_note do |pitch|
  # Keep the original voice dominant so the articulation stays recognizable.
  synth :zawa, note: pitch, attack: 0.05, sustain: 0.15,
    release: 0.125, amp: 0.55

  # A quiet octave reinforces presence without adding another melody.
  synth :sine, note: pitch + 12, attack: 0.01, sustain: 0.04,
    release: 0.16, amp: 0.08

  # A small amount of detuned saw adds body; the short release avoids tails.
  synth :dsaw, note: pitch, detune: 0.07, attack: 0.01, sustain: 0.06,
    release: 0.14, cutoff: 82, amp: 0.07
end

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
      layered_lead_note pitch
      sleep 0.25
    end
  end
end
