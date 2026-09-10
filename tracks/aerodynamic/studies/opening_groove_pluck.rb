# Aerodynamic opening-groove pluck study
#
# Isolated from V10's funk_melody_bar. This keeps the source phrase and its
# opening-groove timing while making the pluck easy to audition and reshape.

use_bpm 120

define :opening_groove_pluck_bar do |fill_bar, filter_stage, phrase_position|
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
  stage_cutoff = [stage_cutoffs[stage_index] + cutoff_lifts[phrase_index], 101].min
  cursor = 0.0

  with_fx :hpf, cutoff: 50 do
    with_fx :distortion, distort: 0.035, mix: 0.08 do
      use_synth :pluck
      events.each do |event|
        onset = event[0].to_f
        sleep onset - cursor if onset > cursor
        play event[1], attack: 0.003, sustain: 0,
          release: event[4], cutoff: [event[3], stage_cutoff].min,
          amp: 0.70 * event[2] * phrase_gains[phrase_index]
        cursor = onset
      end
    end
  end

  sleep 4.0 - cursor if cursor < 4.0
end

# The first twenty bars are the opening groove before the subtraction.
20.times do |bar|
  source_measure = if bar < 12
    9 + (bar % 4)
  else
    13 + ((bar - 12) % 4)
  end
  opening_groove_pluck_bar [12, 16].include?(source_measure),
    [bar / 4, 3].min, bar % 4
end
