# Filter-house club remix derived from aerodynamic_remix_v1.rb.
#
# Hybrid choices retained from the working version:
# - four opening bells spread across the eight-bar introduction
# - one transition bell followed by an eight-second interval
# - progressive remix development inside the fixed section timeline
#
# Core GP4 pitches and rhythms remain intact beneath deterministic remix layers.
# The 1:00-1:32 lead-only passage is intentionally unchanged.

use_bpm 120

# Play one four-beat bar of timestamped tonal events.
# Event format: [onset, duration, note_or_chord, relative_amp]
define :tonal_bar do |events, synth_name, base_amp, cutoff_value|
  use_synth synth_name
  cursor = 0.0

  events.each do |event|
    onset = event[0].to_f
    duration = event[1].to_f
    notes = event[2]
    level = event[3].to_f

    sleep onset - cursor if onset > cursor

    if notes.is_a?(Array)
      play_chord notes,
        attack: 0.01,
        sustain: 0,
        release: duration * 0.82,
        cutoff: cutoff_value,
        amp: base_amp * level
    else
      play notes,
        attack: 0.01,
        sustain: 0,
        release: duration * 0.82,
        cutoff: cutoff_value,
        amp: base_amp * level
    end

    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

# Play one four-beat bar of timestamped drum events.
# Event format: [onset, [[sample_name, amp], ...]]
define :drum_bar do |events|
  cursor = 0.0

  events.each do |event|
    onset = event[0].to_f
    hits = event[1]
    sleep onset - cursor if onset > cursor
    hits.each { |hit| sample hit[0], amp: hit[1] }
    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

define :church_bell do
  with_fx :reverb, room: 1, damp: 0.35, mix: 0.75 do
    # Every layer uses pitches from the GP4 A2-D3-A3-D4 bell voicing.
    use_synth :sine
    play :a2, attack: 0.01, release: 4.6, amp: 0.92
    play :d3, attack: 0.01, release: 4.4, amp: 0.82

    use_synth :pretty_bell
    play_chord [:a2, :d3, :a3, :d4],
      attack: 0.005, release: 4.5, amp: 1.15
  end
end

# GP4 Melodie: exact notes/onsets with a dry clavinet-like articulation.
# Context is :front in the opening and :under_lead when the groove returns.
define :funk_melody_bar do |fill_bar, context, filter_stage|
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

  stage_cutoffs = [78, 88, 98, 108]
  stage_index = [[filter_stage, 0].max, 3].min
  stage_cutoff = stage_cutoffs[stage_index]
  base_amp = context == :front ? 0.80 : 0.48
  cursor = 0.0

  with_fx :hpf, cutoff: 48, mix: 0.20 do
    with_fx :distortion, distort: 0.06, mix: 0.12 do
      with_fx :compressor, threshold: 0.35, slope_above: 0.5,
        clamp_time: 0.01, relax_time: 0.08, mix: 0.30 do
        events.each_with_index do |event, event_index|
          onset = event[0].to_f
          note = event[1]
          level = event[2].to_f
          cutoff_value = [event[3], stage_cutoff].min
          release_value = event[4].to_f
          note_amp = base_amp * level
          pan_value = event_index.even? ? -0.10 : 0.10

          sleep onset - cursor if onset > cursor

          use_synth :pluck
          play note, attack: 0.003, sustain: 0,
            release: release_value, cutoff: cutoff_value,
            amp: note_amp, pan: pan_value

          # A very short same-pitch pulse reinforces the picked transient.
          use_synth :pulse
          play note, pulse_width: 0.18, attack: 0, sustain: 0,
            release: 0.055, cutoff: [88, stage_cutoff].min,
            amp: note_amp * 0.09, pan: pan_value

          cursor = onset
        end
      end
    end
  end

  sleep 4.0 - cursor if cursor < 4.0
end

# GP4 Basse Synthe: alternating measures 9-16 and 29-40.
define :opening_bass_bar do |bar_index|
  if bar_index.even?
    events = [
      [0.0, 1.0, :b2, 1.0],
      [1.5, 0.5, :b2, 1.0],
      [3.5, 0.5, :fs2, 1.0]
    ]
  else
    # The GP4 alternates which member of E2+B2 receives the softer velocity.
    chord_cycle = (bar_index / 2).floor
    b_level = chord_cycle.even? ? 0.66 : 1.0
    e_level = chord_cycle.even? ? 1.0 : 0.66
    events = [
      [0.0, 1.0, :g2, 1.0],
      [1.5, 0.5, :b2, b_level],
      [1.5, 0.5, :e2, e_level],
      [3.5, 0.5, :fs2, 1.0]
    ]
  end
  tonal_bar events, :tb303, 0.27, 62
end

# GP4 Synthe 1 accents on alternating opening/groove bars.
define :opening_synth_accent_bar do |full_bar|
  events = [[0.5, 0.5, :a3, 1.0]]
  if full_bar
    events.push [1.25, 0.5, :a3, 0.82]
    events.push [2.0, 0.25, :a3, 0.9]
  end
  tonal_bar events, :prophet, 0.24, 98
end

# GP4 Daft Percussion 1: alternating measures.
define :percussion_one_bar do |odd_pattern|
  kick = :bd_ada
  snare = :sn_dub
  splash = :drum_splash_soft

  if odd_pattern
    events = [
      [0.0, [[splash, 0.34], [kick, 0.68]]],
      [0.75, [[kick, 0.42]]],
      [1.0, [[snare, 0.58]]],
      [1.5, [[splash, 0.3], [kick, 0.55]]],
      [3.0, [[snare, 0.58]]],
      [3.5, [[kick, 0.42]]]
    ]
  else
    events = [
      [0.0, [[kick, 0.58]]],
      [1.0, [[snare, 0.58]]],
      [1.5, [[splash, 0.3], [kick, 0.55]]],
      [3.0, [[snare, 0.58]]],
      [3.5, [[kick, 0.42]]]
    ]
  end

  drum_bar events
end

# GP4 Daft Percussion 2: enters halfway through each groove section.
define :percussion_two_bar do
  events = []
  16.times do |step|
    onset = step * 0.25
    hits = [[:drum_cymbal_pedal, 0.24]]
    hits.push [:bd_ada, 0.48] if [0, 3, 6].include?(step)
    hits.push [:drum_snare_hard, 0.42] if [4, 12].include?(step)
    events.push [onset, hits]
  end
  drum_bar events
end

# One exact GP4 tapping bar: a four-note sixteenth motif repeated four times.
define :tapping_bar do |notes|
  use_synth :zawa
  use_synth_defaults attack: 0.05, sustain: 0.15,
    release: 0.125, amp: 0.55
  4.times do
    notes.each do |note|
      play note
      sleep 0.25
    end
  end
end

# The Effets track doubles the lower tapping phrase in selected measures.
define :lead_effect_bar do |notes|
  use_synth :dsaw
  with_fx :distortion, distort: 0.08, mix: 0.18 do
    4.times do
      notes.each do |note|
        play note, attack: 0.01, release: 0.12,
          cutoff: 92, amp: 0.16
        sleep 0.25
      end
    end
  end
end

# GP4 Synthes 1 and Harmonique: measures 45-52.
define :post_synth_bar do |bar_index, harmonic_voice|
  if harmonic_voice
    note_bars = [
      [:fs4, :b3, :d4, :b3, :fs4, :b3, :fs4, :g4, :fs4, :e4],
      [:d4, :gs3, :b3, :gs3, :d4, :b3, :d4, :e4, :d4, :cs4],
      [:d4, :g3, :b3, :g3, :d4, :b3, :d4, :e4, :d4, :b3],
      [:cs4, :e3, :a3, :e3, :cs4, :a3, :cs4, :d4, :cs4, :b3]
    ]
    base_amp = 0.39
    synth_name = :blade
  else
    note_bars = [
      [:d4, :fs3, :b3, :fs3, :d4, :b3, :d4, :e4, :d4, :cs4],
      [:b3, :e3, :gs3, :e3, :b3, :gs3, :b3, :cs4, :b3, :a3],
      [:b3, :d3, :g3, :d3, :b3, :g3, :cs4, :d4, :cs4, :b3],
      [:cs4, :e3, :a3, :e3, :e4, :cs4, :a4, :e4]
    ]
    base_amp = 0.52
    synth_name = :prophet
  end

  notes = note_bars[bar_index]
  events = []

  notes.each_with_index do |note, index|
    if bar_index == 3
      onset = index * 0.5
      duration = 0.5
    elsif index < 6
      onset = index * 0.5
      duration = 0.5
    else
      onset = 3.0 + ((index - 6) * 0.25)
      duration = 0.25
    end

    # GP4 harmonic notes at the offbeat positions use a lower velocity.
    level = harmonic_voice && [1, 3, 5].include?(index) ? 0.66 : 1.0
    events.push [onset, duration, note, level]
  end

  tonal_bar events, synth_name, base_amp, 104
end

define :post_bass_bar do
  events = [
    [0.0, 1.0, :fs2, 1.0],
    [1.5, 0.25, :fs2, 0.9],
    [1.75, 0.25, :fs2, 0.9]
  ]
  tonal_bar events, :tb303, 0.28, 64
end

# GP4 measure 49-52 sixteenth-note pedal hi-hat track.
define :post_hihat_bar do
  events = []
  16.times do |step|
    events.push [step * 0.25, [[:drum_cymbal_pedal, 0.3]]]
  end
  drum_bar events
end

# GP4 measure 49-52 secondary drum pattern.
define :post_drums_bar do
  events = [
    [0.0, [[:bd_ada, 0.62]]],
    [1.0, [[:sn_dub, 0.54]]],
    [1.5, [[:drum_tom_lo_hard, 0.4], [:bd_ada, 0.45]]],
    [1.75, [[:drum_tom_lo_hard, 0.4], [:bd_ada, 0.45]]],
    [3.0, [[:sn_dub, 0.54]]]
  ]
  drum_bar events
end

# GP4 Effets sustained chords in measures 49-52.
define :post_effect_chord_bar do |bar_index, pumped|
  chords = [
    [:d4, :b3, :fs3, :b2],
    [:b3, :gs3, :e3, :b2, :gs2],
    [:b3, :g3, :e3, :b2, :e2],
    [:cs4, :g3, :e3, :a2]
  ]
  use_synth :dsaw

  if pumped
    with_fx :slicer, phase: 1, wave: 0, invert_wave: 1,
      amp_min: 0.40, amp_max: 1, smooth: 0.02, mix: 0.55 do
      play_chord chords[bar_index], attack: 0.08, sustain: 3.45,
        release: 0.4, cutoff: 82, amp: 0.17
      sleep 4
    end
  else
    play_chord chords[bar_index], attack: 0.08, sustain: 3.45,
      release: 0.4, cutoff: 82, amp: 0.17
    sleep 4
  end
end

# -----------------------------------------------------------------------------
# Finite remix layers
# -----------------------------------------------------------------------------

remix_chords = [
  [:b3, :d4, :fs4],
  [:b3, :e4, :gs4],
  [:b3, :e4, :g4],
  [:a3, :cs4, :e4]
]

define :intro_drone do
  with_fx :reverb, room: 0.85, mix: 0.24 do
    use_synth :hollow
    play_chord [:d2, :a2], attack: 4, sustain: 23,
      release: 4, cutoff: 68, amp: 0.07
    sleep 32
  end
end

# Same-note sub reinforcement for the opening/returning GP4 bass.
define :remix_opening_sub_bar do |bar_index, context|
  base_amp = context == :front ? 0.08 : 0.06

  if bar_index.even?
    events = [
      [0.0, 1.0, :b2, 0.70],
      [1.5, 0.5, :b2, 0.82],
      [3.5, 0.5, :fs2, 0.82]
    ]
  else
    events = [
      [0.0, 1.0, :g2, 0.70],
      [1.5, 0.5, :b2, 0.68],
      [1.5, 0.5, :e2, 0.68],
      [3.5, 0.5, :fs2, 0.82]
    ]
  end

  tonal_bar events, :sine, base_amp, 72
end

define :remix_stabs_bar do |chord_notes, amp_value, cutoff_value|
  use_synth :dpulse
  sleep 1.5
  play_chord chord_notes, attack: 0.005, sustain: 0, release: 0.14,
    cutoff: cutoff_value, amp: amp_value, pan: -0.18
  sleep 2
  play_chord chord_notes, attack: 0.005, sustain: 0, release: 0.14,
    cutoff: cutoff_value + 3, amp: amp_value * 0.9, pan: 0.18
  sleep 0.5
end

define :remix_pad_bar do |chord_notes, amp_value, cutoff_value, pumped|
  use_synth :hollow

  if pumped
    with_fx :slicer, phase: 1, wave: 0, invert_wave: 1,
      amp_min: 0.45, amp_max: 1, smooth: 0.02, mix: 0.55 do
      play_chord chord_notes, attack: 0.15, sustain: 3.25,
        release: 0.45, cutoff: cutoff_value, amp: amp_value
      sleep 4
    end
  else
    play_chord chord_notes, attack: 0.15, sustain: 3.25,
      release: 0.45, cutoff: cutoff_value, amp: amp_value
    sleep 4
  end
end

# Supplemental filter-house drums only; original GP4 percussion is untouched.
define :filter_house_drums_bar do |stage, final_bar|
  events = []
  closed_amp = stage == :climax ? 0.15 : 0.11
  snap_amp = stage == :climax ? 0.18 : 0.14
  kick_amp = stage == :climax ? 0.28 : (stage == :club ? 0.25 : 0.21)
  open_amp = stage == :climax ? 0.15 : 0.11

  if [:hats, :light, :filtered_kick, :drive].include?(stage)
    [0.5, 1.5, 2.5, 3.5].each_with_index do |onset, index|
      pan_value = index.even? ? -0.22 : 0.22
      events.push [onset, :drum_cymbal_closed, closed_amp, pan_value, nil]
    end
  elsif [:club, :climax].include?(stage)
    events.push [1.5, :drum_cymbal_closed, closed_amp, -0.18, nil]
    events.push [0.5, :drum_cymbal_open, open_amp, -0.12, nil]
    unless final_bar
      events.push [2.5, :drum_cymbal_open, open_amp, 0.12, nil]
      events.push [3.5, :drum_cymbal_closed, closed_amp, 0.18, nil]
    end
  end

  if [:light, :drive, :club, :climax].include?(stage)
    events.push [1.0, :perc_snap, snap_amp, -0.08, nil]
    unless final_bar
      events.push [3.0, :perc_snap, snap_amp, 0.08, nil]
    end
  end

  if stage == :filtered_kick
    4.times do |beat|
      events.push [beat.to_f, :bd_haus, kick_amp, 0, 42]
    end
  elsif [:drive, :club, :climax].include?(stage)
    kick_count = final_bar ? 3 : 4
    kick_count.times do |beat|
      events.push [beat.to_f, :bd_haus, kick_amp, 0, nil]
    end
  end

  events = events.sort_by { |event| event[0] }
  cursor = 0.0
  events.each do |event|
    onset = event[0].to_f
    sleep onset - cursor if onset > cursor
    if event[4]
      with_fx :hpf, cutoff: event[4] do
        sample event[1], amp: event[2], pan: event[3]
      end
    else
      sample event[1], amp: event[2], pan: event[3]
    end
    cursor = onset
  end
  sleep 4.0 - cursor if cursor < 4.0
end

# A one-beat chop derived only from the existing D4-B3-A3-B3 funk notes.
define :funk_micro_chop_bar do |amp_value|
  use_synth :pluck
  sleep 3
  [:d4, :b3, :a3, :b3].each_with_index do |note, note_index|
    pan_value = note_index.even? ? -0.08 : 0.08
    play note, attack: 0.002, sustain: 0, release: 0.075,
      cutoff: 96, amp: amp_value, pan: pan_value
    sleep 0.25
  end
end

define :remix_lead_double do |notes, amp_value, cutoff_value|
  use_synth :blade
  with_fx :reverb, room: 0.25, mix: 0.08 do
    note_index = 0
    4.times do
      notes.each do |note|
        pan_value = note_index.even? ? -0.14 : 0.14
        play note, attack: 0.01, sustain: 0, release: 0.14,
          cutoff: cutoff_value, amp: amp_value, pan: pan_value
        note_index += 1
        sleep 0.25
      end
    end
  end
end

define :transition_riser do
  with_fx :rhpf, cutoff: 58, cutoff_slide: 12, res: 0.35 do |filter_fx|
    use_synth :noise
    synth :noise, attack: 3, sustain: 8.5, release: 0.5, amp: 0.045
    control filter_fx, cutoff: 106

    use_synth :hollow
    play :d2, attack: 3, sustain: 8.5, release: 0.5,
      cutoff: 68, amp: 0.05
    sleep 12
  end
end

# Same-note reinforcement for the primary post-bell synth voice.
define :post_primary_double_bar do |bar_index, amp_value|
  note_bars = [
    [:d4, :fs3, :b3, :fs3, :d4, :b3, :d4, :e4, :d4, :cs4],
    [:b3, :e3, :gs3, :e3, :b3, :gs3, :b3, :cs4, :b3, :a3],
    [:b3, :d3, :g3, :d3, :b3, :g3, :cs4, :d4, :cs4, :b3],
    [:cs4, :e3, :a3, :e3, :e4, :cs4, :a4, :e4]
  ]
  notes = note_bars[bar_index]
  events = []

  notes.each_with_index do |note, index|
    if bar_index == 3
      onset = index * 0.5
      duration = 0.5
    elsif index < 6
      onset = index * 0.5
      duration = 0.5
    else
      onset = 3.0 + ((index - 6) * 0.25)
      duration = 0.25
    end
    events.push [onset, duration, note, 1.0]
  end

  tonal_bar events, :blade, amp_value, 98
end

define :post_sub_bar do
  events = [
    [0.0, 1.0, :fs2, 0.72],
    [1.5, 0.25, :fs2, 0.82],
    [1.75, 0.25, :fs2, 0.82]
  ]
  tonal_bar events, :sine, 0.07, 70
end

# -----------------------------------------------------------------------------
# Fixed remix timeline - all original section cues remain unchanged.
# -----------------------------------------------------------------------------

opening_bell_bars = 8
opening_groove_bars = 22
lead_only_bars = 16
lead_stage_one_bars = 8
lead_stage_two_bars = 16
transition_wait_beats = 16
post_melody_only_bars = 12
post_layered_bars = 16

# 0:00-0:16: bells with a finite atmospheric drone.
cue :section_opening_bells
in_thread { intro_drone }
opening_bell_bars.times do |bar|
  church_bell if bar.even?
  sleep 4
end

# 0:16-1:00: opening groove grows every four bars.
cue :section_opening_groove
opening_groove_bars.times do |bar|
  if bar < 12
    source_measure = 9 + (bar % 4)
  else
    source_measure = 13 + ((bar - 12) % 4)
  end
  chord_notes = remix_chords[bar % 4]
  filter_stage = [bar / 4, 3].min

  in_thread do
    funk_melody_bar [12, 16].include?(source_measure), :front, filter_stage
  end
  in_thread { opening_bass_bar source_measure - 9 }
  in_thread { remix_opening_sub_bar source_measure - 9, :front }
  in_thread { percussion_one_bar source_measure.odd? }

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar [12, 16].include?(source_measure)
    end
  end

  in_thread { percussion_two_bar } if bar >= 12

  if bar >= 4 && bar < 8
    in_thread { filter_house_drums_bar :hats, false }
  elsif bar >= 8 && bar < 12
    in_thread { filter_house_drums_bar :filtered_kick, false }
    in_thread { remix_stabs_bar chord_notes, 0.08, 84 }
  elsif bar >= 12 && bar < 16
    in_thread { filter_house_drums_bar :drive, false }
  elsif bar >= 16
    in_thread { filter_house_drums_bar :club, bar == 21 }
    in_thread { remix_stabs_bar chord_notes, 0.09, 90 }
    in_thread { remix_pad_bar chord_notes, 0.06, 82, true }
  end

  if [7, 11, 15, 21].include?(bar)
    in_thread { funk_micro_chop_bar 0.14 }
  end
  sleep 4
end

lower_lead = [
  [:d4, :fs3, :b3, :fs3],
  [:d4, :gs3, :b3, :gs3],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3]
]
upper_lead = [
  # Mixed-register version from the approved standalone lead. It preserves
  # the phrase while removing the piercing D5-G5 anchor notes.
  [:d4, :fs4, :b3, :fs4],
  [:d4, :gs4, :b3, :gs4],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3]
]

# 1:00-1:32: no drums, bass, stabs, or pads; only lead timbre is widened.
cue :section_lead_only
lead_only_bars.times do |bar|
  phrase_bar = bar % 4
  lead_notes = bar < 8 ? lower_lead[phrase_bar] : upper_lead[phrase_bar]

  if bar < 8
    double_amp = 0.07
    double_cutoff = 90
  elsif bar < 12
    double_amp = 0.09
    double_cutoff = 98
  else
    double_amp = 0.12
    double_cutoff = [100, 103, 106, 110][bar - 12]
  end

  in_thread { tapping_bar lead_notes }
  in_thread { remix_lead_double lead_notes, double_amp, double_cutoff }
  sleep 4
end

# 1:32-1:48: lead plus first-stage groove.
cue :section_lead_stage_one
lead_stage_one_bars.times do |bar|
  source_measure = 29 + (bar % 4)
  phrase_bar = bar % 4
  chord_notes = remix_chords[bar % 4]

  in_thread { tapping_bar upper_lead[phrase_bar] }
  in_thread { remix_lead_double upper_lead[phrase_bar], 0.08, 98 }
  in_thread { lead_effect_bar lower_lead[phrase_bar] }
  in_thread do
    funk_melody_bar source_measure == 32, :under_lead, 3
  end
  in_thread { opening_bass_bar source_measure - 29 }
  in_thread { remix_opening_sub_bar source_measure - 29, :under_lead }
  in_thread { percussion_one_bar source_measure.odd? }
  in_thread { filter_house_drums_bar :light, false }

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar source_measure == 32
    end
  end

  in_thread { remix_stabs_bar chord_notes, 0.09, 88 } if bar >= 4
  sleep 4
end

# 1:48-2:20: full progressive club treatment.
cue :section_lead_stage_two
lead_stage_two_bars.times do |bar|
  source_measure = 33 + (bar % 8)
  phrase_bar = bar % 4
  chord_notes = remix_chords[bar % 4]
  final_bar = bar == 15

  in_thread { tapping_bar lower_lead[phrase_bar] }
  in_thread { remix_lead_double lower_lead[phrase_bar], 0.09, 102 }
  in_thread do
    funk_melody_bar [36, 40].include?(source_measure), :under_lead, 3
  end
  in_thread { opening_bass_bar source_measure - 29 }
  in_thread { remix_opening_sub_bar source_measure - 29, :under_lead }
  in_thread { percussion_one_bar source_measure.odd? }
  in_thread { percussion_two_bar }

  if source_measure >= 37
    in_thread { lead_effect_bar lower_lead[phrase_bar] }
  end

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar [36, 40].include?(source_measure)
    end
  end

  drum_stage = bar >= 8 ? :climax : :club
  in_thread { filter_house_drums_bar drum_stage, final_bar }

  if bar >= 4
    stab_amp = bar >= 12 ? 0.14 : (bar >= 8 ? 0.12 : 0.10)
    pad_amp = bar >= 12 ? 0.10 : (bar >= 8 ? 0.08 : 0.065)
    pad_cutoff = bar >= 8 ? 92 : 82
    in_thread { remix_stabs_bar chord_notes, stab_amp, pad_cutoff + 4 }
    in_thread { remix_pad_bar chord_notes, pad_amp, pad_cutoff, true }
  end

  if [7, 15].include?(bar)
    in_thread { funk_micro_chop_bar 0.15 }
  end
  sleep 4
end

# 2:20-2:28: bell, four clear beats, then a twelve-beat riser.
cue :section_transition_bell
church_bell
in_thread do
  sleep 4
  transition_riser
end
sleep transition_wait_beats

# 2:28-2:52: three melody-only passes with gradual harmonic width.
cue :section_post_bell_melody_only
(post_melody_only_bars / 4).times do |pass|
  4.times do |bar|
    chord_notes = remix_chords[bar]

    in_thread do
      with_fx :pan, pan: -0.12 do
        post_synth_bar bar, false
      end
    end
    in_thread do
      with_fx :pan, pan: 0.12 do
        post_synth_bar bar, true
      end
    end

    if pass >= 1
      pad_amp = pass == 1 ? 0.055 : 0.075
      in_thread { remix_pad_bar chord_notes, pad_amp, 80, false }
    end

    if pass == 2
      in_thread do
        with_fx :pan, pan: 0.14 do
          post_primary_double_bar bar, 0.06
        end
      end
    end

    sleep 4
  end
end

# 2:52-3:24: four increasingly dense layered passes.
cue :section_post_bell_layered
(post_layered_bars / 4).times do |pass|
  4.times do |bar|
    chord_notes = remix_chords[bar]
    final_bar = pass == 3 && bar == 3
    layered_bar = (pass * 4) + bar
    pan_width = pass == 3 ? 0.20 : 0.12

    in_thread do
      with_fx :pan, pan: -pan_width do
        post_synth_bar bar, false
      end
    end
    in_thread do
      with_fx :pan, pan: pan_width do
        post_synth_bar bar, true
      end
    end
    in_thread { post_bass_bar }
    in_thread { post_sub_bar }
    in_thread { post_hihat_bar }
    in_thread { post_drums_bar }
    in_thread { post_effect_chord_bar bar, pass >= 1 }

    drum_stage = pass >= 2 ? :climax : :club
    in_thread { filter_house_drums_bar drum_stage, final_bar }

    if pass >= 2
      pad_amp = pass == 3 ? 0.10 : 0.08
      stab_amp = pass == 3 ? 0.14 : 0.10
      cutoff_value = pass == 3 ? 94 : 86
      in_thread { remix_pad_bar chord_notes, pad_amp, cutoff_value, true }
      in_thread { remix_stabs_bar chord_notes, stab_amp, cutoff_value + 4 }
    end

    if pass == 3
      in_thread do
        with_fx :pan, pan: 0.14 do
          post_primary_double_bar bar, 0.07
        end
      end
    end

    if [7, 15].include?(layered_bar)
      in_thread { funk_micro_chop_bar 0.15 }
    end
    sleep 4
  end
end

# 3:24: one unobstructed final bell and its natural reverb tail.
cue :section_final_bell
church_bell
sleep 5

cue :arrangement_complete
