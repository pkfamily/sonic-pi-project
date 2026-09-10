# Aerodynamic opening-groove pulse hybrid study
#
# New approach after the metallic pluck and muffled additive variants:
# a bright, focused pulse core with additive body and definition. No
# sub-octave layer is used, so the phrase keeps its articulation and presence.

use_bpm 120

define :pulse_hybrid_note do |pitch, level, phrase_gain|
  synth :dpulse, note: pitch, pulse_width: 0.30, detune: 0.015,
    attack: 0.004, sustain: 0.01, release: 0.10,
    cutoff: 104, amp: 0.30 * level * phrase_gain

  # Adds body at the fundamental without adding low-end mud.
  synth :sine, note: pitch, attack: 0.008, sustain: 0.02,
    release: 0.08, amp: 0.08 * level * phrase_gain

  # A restrained upper partial restores definition without a saw-like edge.
  synth :tri, note: pitch + 12, attack: 0.004, sustain: 0.008,
    release: 0.06, cutoff: 112, amp: 0.035 * level * phrase_gain
end

define :pulse_hybrid_bar do |fill_bar, filter_stage, phrase_position|
  events = [
    [0.5, :d4, 1.12, 104, 0.22],
    [1.0, :b3, 0.84, 96, 0.11]
  ]
  events.push [1.25, :a3, 0.66, 92, 0.11] if fill_bar
  events.concat [
    [2.0, :a3, 1.00, 100, 0.11],
    [2.25, :b3, 0.76, 94, 0.11],
    [2.5, :d4, 1.18, 108, 0.22],
    [3.0, :b3, 0.88, 98, 0.11]
  ]

  stage_cutoffs = [88, 94, 100, 106]
  phrase_gains = [0.96, 1.00, 0.98, 1.04]
  phrase_index = phrase_position % 4
  cutoff_value = [stage_cutoffs[[filter_stage, 0].max], 110].min
  cursor = 0.0

  events.each do |event|
    onset = event[0].to_f
    sleep onset - cursor if onset > cursor
    pulse_hybrid_note event[1], event[2], phrase_gains[phrase_index]
    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

20.times do |bar|
  source_measure = if bar < 12
    9 + (bar % 4)
  else
    13 + ((bar - 12) % 4)
  end
  pulse_hybrid_bar [12, 16].include?(source_measure), [bar / 4, 3].min, bar % 4
end
