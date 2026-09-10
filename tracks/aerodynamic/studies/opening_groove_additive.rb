# Aerodynamic opening-groove additive synthesis study
#
# Derived from opening_groove_pluck.rb. The phrase and timing are unchanged;
# each note is built from simple layered partials instead of :pluck.

use_bpm 120

define :additive_groove_note do |pitch, level, cutoff_value, release_value, phrase_gain|
  # Fundamental: warm and stable.
  synth :sine, note: pitch - 12, attack: 0.008, sustain: 0.025,
    release: release_value * 0.9, amp: 0.28 * level * phrase_gain

  # Body: triangle supplies a little harmonic definition without the saw edge.
  synth :tri, note: pitch, attack: 0.006, sustain: 0.02,
    release: release_value, cutoff: cutoff_value,
    amp: 0.34 * level * phrase_gain

  # Upper partial: short and quiet, for articulation rather than metallic sheen.
  synth :sine, note: pitch + 12, attack: 0.004, sustain: 0.01,
    release: release_value * 0.65, amp: 0.07 * level * phrase_gain
end

define :opening_groove_additive_bar do |fill_bar, filter_stage, phrase_position|
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

  stage_cutoffs = [78, 85, 92, 98]
  phrase_gains = [0.96, 1.00, 0.98, 1.04]
  cutoff_lifts = [0, 2, 1, 3]
  stage_index = [[filter_stage, 0].max, 3].min
  phrase_index = phrase_position % 4
  cutoff_value = [stage_cutoffs[stage_index] + cutoff_lifts[phrase_index], 101].min
  cursor = 0.0

  with_fx :hpf, cutoff: 42 do
    events.each do |event|
      onset = event[0].to_f
      sleep onset - cursor if onset > cursor
      additive_groove_note event[1], event[2], cutoff_value, event[4],
        phrase_gains[phrase_index]
      cursor = onset
    end
  end

  sleep 4.0 - cursor if cursor < 4.0
end

20.times do |bar|
  source_measure = if bar < 12
    9 + (bar % 4)
  else
    13 + ((bar - 12) % 4)
  end
  opening_groove_additive_bar [12, 16].include?(source_measure),
    [bar / 4, 3].min, bar % 4
end
