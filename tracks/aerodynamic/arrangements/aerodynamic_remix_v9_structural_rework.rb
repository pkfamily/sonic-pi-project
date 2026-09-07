# Structural re-edit derived from aerodynamic_remix_v8_simple_lead_entry.rb.
#
# Hybrid choices retained from the working version:
# - four opening bells spread across the eight-bar introduction
# - one transition bell followed by an eight-second interval
# - progressive remix development inside the fixed section timeline
#
# Core GP4 pitches and rhythms remain intact beneath deterministic remix layers.
# V8's clean lead entrance and corrected post-bell fill remain intact beneath
# a shorter macro arrangement, an earlier lead, and a four-bar funk callback.

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

# A darker, quieter ending strike. Opening and transition bells continue to
# use the full church_bell voice above.
define :final_church_bell do
  with_fx :reverb, room: 0.9, damp: 0.45, mix: 0.58 do
    with_fx :lpf, cutoff: 100 do
      use_synth :sine
      play :a2, attack: 0.01, release: 3.8, amp: 0.58
      play :d3, attack: 0.01, release: 3.6, amp: 0.50

      use_synth :pretty_bell
      play_chord [:a2, :d3, :a3, :d4],
        attack: 0.005, release: 3.7, amp: 0.68
    end
  end
end

# GP4 Melodie: exact notes/onsets with a dry clavinet-like articulation.
# Context is :front in the opening and :under_lead when the groove returns.
define :funk_melody_bar do |fill_bar, context, filter_stage, phrase_position|
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

  stage_cutoffs = [80, 88, 96, 101]
  phrase_gains = [0.96, 1.00, 0.98, 1.04]
  cutoff_lifts = [0, 2, 1, 3]
  stage_index = [[filter_stage, 0].max, 3].min
  phrase_index = phrase_position % 4
  stage_cutoff = [stage_cutoffs[stage_index] + cutoff_lifts[phrase_index], 104].min
  base_amp = context == :front ? 0.82 : 0.42
  pulse_level = context == :front ? 0.09 : 0.06
  phrase_gain = phrase_gains[phrase_index]
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
          note_amp = base_amp * level * phrase_gain
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
            amp: note_amp * pulse_level, pan: pan_value

          cursor = onset
        end
      end
    end
  end

  sleep 4.0 - cursor if cursor < 4.0
end

# GP4 Basse Synthe: alternating measures 9-16 and 29-40.
define :opening_bass_bar do |bar_index, amp_value, cutoff_value|
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
  tonal_bar events, :tb303, amp_value, cutoff_value
end

# GP4 Synthe 1 accents on alternating opening/groove bars.
define :opening_synth_accent_bar do |full_bar, amp_value|
  events = [[0.5, 0.5, :a3, 1.0]]
  if full_bar
    events.push [1.25, 0.5, :a3, 0.82]
    events.push [2.0, 0.25, :a3, 0.9]
  end
  tonal_bar events, :prophet, amp_value, 98
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
define :post_synth_bar do |bar_index, harmonic_voice, end_beat,
  cutoff_value, amp_scale|
  if harmonic_voice
    note_bars = [
      [:fs4, :b3, :d4, :b3, :fs4, :b3, :fs4, :g4, :fs4, :e4],
      [:d4, :gs3, :b3, :gs3, :d4, :b3, :d4, :e4, :d4, :cs4],
      [:d4, :g3, :b3, :g3, :d4, :b3, :d4, :e4, :d4, :b3],
      [:cs4, :e3, :a3, :e3, :cs4, :a3, :cs4, :d4, :cs4, :b3]
    ]
    base_amp = 0.34
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
    # Eight-note bars use straight eighth notes. Ten-note bars use six
    # eighth notes followed by four sixteenths so they remain four beats.
    if notes.length == 8
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

  timed_events = events.select { |event| event[0] < end_beat }
  tonal_bar timed_events, synth_name, base_amp * amp_scale, cutoff_value
end

define :post_bass_bar do
  events = [
    [0.0, 1.0, :fs2, 1.0],
    [1.5, 0.25, :fs2, 0.9],
    [1.75, 0.25, :fs2, 0.9]
  ]
  tonal_bar events, :tb303, 0.28, 64
end

# GP4 measure 49-52 sixteenth-note pedal hi-hat track with section gain.
define :post_hihat_bar do |amp_value, swing_amount, phrase_position|
  events = []
  velocity_levels = [1.00, 0.62, 0.80, 0.66]
  phrase_gains = [0.96, 1.00, 0.98, 1.03]
  phrase_gain = phrase_gains[phrase_position % 4]
  16.times do |step|
    onset = (step * 0.25) + (step.odd? ? swing_amount : 0)
    level = velocity_levels[step % 4]
    events.push [onset,
      [[:drum_cymbal_pedal, amp_value * level * phrase_gain]]]
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

# Snare and one centered tom accent without another kick layer.
define :post_backbeat_bar do
  events = [
    [1.0, [[:sn_dub, 0.52]]],
    [1.5, [[:drum_tom_lo_hard, 0.36]]],
    [3.0, [[:sn_dub, 0.52]]]
  ]
  drum_bar events
end

# A finite deconstruction bar with no events after beat two.
define :sparse_deconstruction_drums_bar do
  events = [
    [0.0, [[:bd_haus, 0.22]]],
    [1.5, [[:drum_cymbal_pedal, 0.08]]],
    [2.0, [[:sn_dub, 0.18]]]
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
        release: 0.3, cutoff: 82, amp: 0.14
      sleep 4
    end
  else
    play_chord chords[bar_index], attack: 0.08, sustain: 3.45,
      release: 0.3, cutoff: 82, amp: 0.14
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
  base_amp = context == :front ? 0.06 : 0.045

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

define :remix_stabs_bar do |chord_notes, amp_value, cutoff_value,
  stereo_width|
  use_synth :dpulse
  sleep 1.5
  play_chord chord_notes, attack: 0.005, sustain: 0, release: 0.12,
    cutoff: cutoff_value, amp: amp_value, pan: -stereo_width
  sleep 2
  play_chord chord_notes, attack: 0.005, sustain: 0, release: 0.12,
    cutoff: cutoff_value + 3, amp: amp_value * 0.9, pan: stereo_width
  sleep 0.5
end

define :remix_pad_bar do |chord_notes, amp_value, cutoff_value, pumped,
  pan_value|
  use_synth :hollow

  if pumped
    with_fx :slicer, phase: 1, wave: 0, invert_wave: 1,
      amp_min: 0.45, amp_max: 1, smooth: 0.02, mix: 0.55 do
      play_chord chord_notes, attack: 0.15, sustain: 3.15,
        release: 0.35, cutoff: cutoff_value, amp: amp_value,
        pan: pan_value
      sleep 4
    end
  else
    play_chord chord_notes, attack: 0.15, sustain: 3.15,
      release: 0.35, cutoff: cutoff_value, amp: amp_value,
      pan: pan_value
    sleep 4
  end
end

# Supplemental filter-house drums only; original GP4 percussion is untouched.
define :filter_house_drums_bar do |stage, final_bar, swing_amount|
  events = []
  closed_amp = stage == :climax ? 0.15 : 0.11
  snap_amp = stage == :climax ? 0.18 : 0.14
  kick_amp = stage == :climax ? 0.28 : (stage == :club ? 0.25 : 0.21)
  open_amp = stage == :climax ? 0.15 : 0.11

  if [:hats, :light, :filtered_kick, :drive].include?(stage)
    [0.5, 1.5, 2.5, 3.5].each_with_index do |onset, index|
      pan_value = index.even? ? -0.22 : 0.22
      timed_onset = onset + (index.odd? ? swing_amount : 0)
      hat_level = [0.90, 1.00, 0.94, 1.05][index]
      events.push [timed_onset, :drum_cymbal_closed,
        closed_amp * hat_level, pan_value, nil]
    end
  elsif [:club, :climax].include?(stage)
    events.push [1.5 + swing_amount, :drum_cymbal_closed,
      closed_amp, -0.18, nil]
    events.push [0.5, :drum_cymbal_open, open_amp, -0.12, nil]
    unless final_bar
      events.push [2.5, :drum_cymbal_open, open_amp, 0.12, nil]
      events.push [3.5 + swing_amount, :drum_cymbal_closed,
        closed_amp, 0.18, nil]
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

# Four-on-the-floor weight without another layer of hats or snares.
define :club_kick_bar do |amp_value, final_bar|
  events = []
  kick_count = final_bar ? 3 : 4
  kick_count.times do |beat|
    events.push [beat.to_f, [[:bd_haus, amp_value]]]
  end
  drum_bar events
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

# Supplemental beat-only passage used when all tonal layers are removed.
define :beat_only_bar do |stage, swing_amount, final_bar|
  filter_house_drums_bar stage, final_bar, swing_amount
end

# Two silent beats followed by a compact club drop on beat 2.
define :delayed_drop_drums_bar do
  events = [
    [2.0, [[:bd_haus, 0.28]]],
    [2.5, [[:drum_cymbal_open, 0.13]]],
    [3.0, [[:bd_haus, 0.28], [:perc_snap, 0.16]]],
    [3.5, [[:drum_cymbal_closed, 0.12]]]
  ]
  drum_bar events
end

# Half-time perception on the unchanged 120 BPM grid.
define :half_time_drums_bar do
  events = []
  8.times do |step|
    hits = [[:drum_cymbal_pedal, step.even? ? 0.08 : 0.06]]
    hits.push [:bd_haus, 0.27] if step == 0
    hits.push [:sn_dub, 0.25] if step == 4
    events.push [step * 0.5, hits]
  end
  drum_bar events
end

# A dry, truncated opening phrase followed by 1.28 beats of true silence.
# The final note begins at beat 2.5 and its 0.22-beat release ends at 2.72.
define :simple_lead_entry_bar do
  events = [
    [0.5, :d4, 1.12, 104, 0.22],
    [1.0, :b3, 0.84, 96, 0.11],
    [2.0, :a3, 1.00, 100, 0.11],
    [2.25, :b3, 0.76, 94, 0.11],
    [2.5, :d4, 1.18, 104, 0.22]
  ]
  cursor = 0.0

  with_fx :hpf, cutoff: 48, mix: 0.20 do
    events.each_with_index do |event, event_index|
      onset = event[0].to_f
      pan_value = event_index.even? ? -0.05 : 0.05
      note_amp = 0.76 * event[2]
      sleep onset - cursor if onset > cursor

      use_synth :pluck
      play event[1], attack: 0.003, sustain: 0,
        release: event[4], cutoff: event[3],
        amp: note_amp, pan: pan_value
      use_synth :pulse
      play event[1], pulse_width: 0.18, attack: 0, sustain: 0,
        release: 0.055, cutoff: 88,
        amp: note_amp * 0.05, pan: pan_value
      cursor = onset
    end
  end

  sleep 4.0 - cursor
end

# A reduced GP4 primary-drum pattern for the second subtraction bar. Explicit
# releases leave the following melody-and-bass bar free of percussion tails.
define :simple_primary_drums_bar do
  sample :bd_ada, amp: 0.54, release: 0.20
  sleep 1
  sample :sn_dub, amp: 0.54, release: 0.18
  sleep 0.5
  sample :bd_ada, amp: 0.48, release: 0.16
  sleep 1.5
  sample :sn_dub, amp: 0.50, release: 0.18
  sleep 1
end

# Three beats of the approved lead/groove followed by an accelerating D4
# stutter. All sounding events terminate before the next downbeat.
define :transition_stutter_bar do |lead_notes|
  in_thread do
    use_synth :zawa
    use_synth_defaults attack: 0.05, sustain: 0.15,
      release: 0.125, amp: 0.55
    3.times do
      lead_notes.each do |note|
        play note
        sleep 0.25
      end
    end
  end

  in_thread do
    use_synth :blade
    note_index = 0
    3.times do
      lead_notes.each do |note|
        pan_value = note_index.even? ? -0.14 : 0.14
        play note, attack: 0.01, sustain: 0, release: 0.14,
          cutoff: 98, amp: 0.075, pan: pan_value
        note_index += 1
        sleep 0.25
      end
    end
  end

  in_thread do
    events = [
      [0.5, :d4, 1.12, 0.22],
      [1.0, :b3, 0.84, 0.11],
      [2.0, :a3, 1.00, 0.11],
      [2.25, :b3, 0.76, 0.11],
      [2.5, :d4, 1.18, 0.22]
    ]
    cursor = 0.0
    use_synth :pluck
    events.each do |event|
      onset = event[0].to_f
      sleep onset - cursor if onset > cursor
      play event[1], attack: 0.003, sustain: 0,
        release: event[3], cutoff: 100, amp: 0.40 * event[2]
      cursor = onset
    end
    sleep 4.0 - cursor if cursor < 4.0
  end

  in_thread do
    events = [
      [0.0, 1.0, :g2, 1.0],
      [1.5, 0.5, [:b2, :e2], 0.78]
    ]
    tonal_bar events, :tb303, 0.23, 58
  end

  in_thread do
    drum_bar [
      [0.0, [[:bd_haus, 0.24]]],
      [1.0, [[:sn_dub, 0.20]]],
      [2.0, [[:bd_haus, 0.22]]]
    ]
  end

  sleep 3
  use_synth :pluck
  intervals = [0.5, 0.25, 0.125, 0.125]
  levels = [0.10, 0.095, 0.085, 0.075]
  intervals.each_with_index do |interval, index|
    play :d4, attack: 0.001, sustain: 0, release: 0.05,
      cutoff: 98, amp: levels[index]
    sleep interval
  end
end

# Both post-bell voices truncated at the same beat while the bar still
# consumes four beats, creating intentional silence at its end.
define :post_synth_cut_bar do |bar_index, end_beat, primary_cutoff,
  harmonic_cutoff, harmonic_scale, pan_width|
  in_thread do
    with_fx :pan, pan: -pan_width do
      post_synth_bar bar_index, false, end_beat, primary_cutoff, 1.0
    end
  end
  in_thread do
    with_fx :pan, pan: pan_width do
      post_synth_bar bar_index, true, end_beat,
        harmonic_cutoff, harmonic_scale
    end
  end
  sleep 4
end

# A short A-D resonance followed by more than two beats of actual silence.
define :ending_decay_bar do |beat_count|
  with_fx :reverb, room: 0.65, damp: 0.5, mix: 0.22 do
    use_synth :hollow
    play_chord [:a2, :d3, :a3], attack: 0.05, sustain: 1.05,
      release: 0.75, cutoff: 72, amp: 0.045
  end
  sleep beat_count
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

# Eight beats of restrained atmosphere after one unobstructed bell bar.
# Both voices finish 0.7 beat before the post-bell melody enters.
define :short_transition_bed do
  with_fx :rhpf, cutoff: 78, res: 0.25 do
    use_synth :noise
    synth :noise, attack: 1.5, sustain: 5.4, release: 0.4, amp: 0.025

    use_synth :hollow
    play :d2, attack: 1.5, sustain: 5.4, release: 0.4,
      cutoff: 68, amp: 0.028
    sleep 8
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
  tonal_bar events, :sine, 0.055, 70
end

# -----------------------------------------------------------------------------
# Structural re-edit at 120 BPM / 4-4.
#
# Cue beats:
#   opening groove 32 (0:16)     lead only 128 (1:04)
#   lead stage one 176 (1:28)    lead stage two 200 (1:40)
#   transition bell 264 (2:12)   post melody 276 (2:18)
#   post rhythm 324 (2:42)       funk callback 396 (3:18)
#   final decay 412 (3:26)       final bell 416 (3:28)
# -----------------------------------------------------------------------------

opening_bell_bars = 8
opening_groove_bars = 24
lead_only_bars = 12
lead_stage_one_bars = 6
lead_stage_two_bars = 16
transition_wait_beats = 12
post_melody_only_bars = 12
post_layered_bars = 18
opening_callback_bars = 4
final_transition_beats = 4

# 0:00-0:16: four bells at 0:00, 0:04, 0:08, and 0:12.
cue :section_opening_bells
in_thread { intro_drone }
opening_bell_bars.times do |bar|
  church_bell if bar.even?
  sleep 4
end

# 0:16-1:04: twenty groove bars followed by V8's four-bar subtraction.
cue :section_opening_groove
opening_groove_bars.times do |bar|
  if bar < 12
    source_measure = 9 + (bar % 4)
  else
    source_measure = 13 + ((bar - 12) % 4)
  end

  chord_notes = remix_chords[bar % 4]
  filter_stage = [bar / 4, 3].min
  if bar < 4
    bass_amp = 0.235
    bass_cutoff = 58
  elsif bar < 8
    bass_amp = 0.245
    bass_cutoff = 60
  elsif bar < 16
    bass_amp = 0.255
    bass_cutoff = 62
  elsif bar < 20
    bass_amp = 0.265
    bass_cutoff = 64
  else
    bass_amp = 0.245
    bass_cutoff = 60
  end

  if bar >= 20
    subtraction_bar = bar - 20

    if subtraction_bar < 3
      subtraction_bass_amps = [0.245, 0.235, 0.225]
      subtraction_bass_cutoffs = [60, 58, 58]

      in_thread do
        funk_melody_bar [12, 16].include?(source_measure),
          :front, filter_stage, bar % 4
      end
      in_thread do
        opening_bass_bar source_measure - 9,
          subtraction_bass_amps[subtraction_bar],
          subtraction_bass_cutoffs[subtraction_bar]
      end

      if subtraction_bar == 0
        in_thread { remix_opening_sub_bar source_measure - 9, :front }
      end

      if subtraction_bar == 0
        in_thread { percussion_one_bar source_measure.odd? }
      elsif subtraction_bar == 1
        in_thread { simple_primary_drums_bar }
      end
    else
      in_thread { simple_lead_entry_bar }
    end
  else
    in_thread do
      funk_melody_bar [12, 16].include?(source_measure),
        :front, filter_stage, bar % 4
    end
    in_thread do
      opening_bass_bar source_measure - 9, bass_amp, bass_cutoff
    end
    if bar >= 4
      in_thread { remix_opening_sub_bar source_measure - 9, :front }
    end

    in_thread { percussion_one_bar source_measure.odd? } if bar < 16

    if [7, 11, 15, 19].include?(bar)
      in_thread do
        opening_synth_accent_bar [12, 16].include?(source_measure), 0.18
      end
    end

    if bar >= 16
      in_thread { percussion_two_bar }
    end
  end

  if bar >= 4 && bar < 8
    in_thread { filter_house_drums_bar :hats, false, 0.020 }
  elsif bar >= 8 && bar < 12
    in_thread { filter_house_drums_bar :filtered_kick, false, 0.025 }
  elsif bar >= 12 && bar < 16
    in_thread { club_kick_bar 0.20, false }
  elsif bar >= 16 && bar < 20
    in_thread { club_kick_bar 0.22, false }
  end

  if [9, 11, 13, 15, 17, 19].include?(bar)
    in_thread { remix_stabs_bar chord_notes, 0.08, 90, 0.12 }
  end

  if [16, 18].include?(bar)
    pad_pan = bar % 4 == 0 ? -0.05 : 0.05
    in_thread { remix_pad_bar chord_notes, 0.06, 86, true, pad_pan }
  end

  if bar == 11
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
  [:d4, :fs4, :b3, :fs4],
  [:d4, :gs4, :b3, :gs4],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3]
]

# 1:04-1:28: isolated lead; internal rhythm and voices match V8.
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

# 1:28-1:40: six bars of lead plus a lightly swung first-stage groove.
cue :section_lead_stage_one
lead_stage_one_bars.times do |bar|
  source_measure = 29 + (bar % 4)
  phrase_bar = bar % 4
  chord_notes = remix_chords[bar % 4]

  in_thread { tapping_bar upper_lead[phrase_bar] }
  in_thread { remix_lead_double upper_lead[phrase_bar], 0.08, 98 }
  in_thread do
    funk_melody_bar source_measure == 32, :under_lead, 3, phrase_bar
  end
  in_thread do
    bass_amp = bar < 4 ? 0.220 : 0.230
    bass_cutoff = bar < 4 ? 58 : 60
    opening_bass_bar source_measure - 29, bass_amp, bass_cutoff
  end

  if bar >= 4
    in_thread do
      remix_opening_sub_bar source_measure - 29, :under_lead
    end
  end

  in_thread { lead_effect_bar lower_lead[phrase_bar] } if [4, 6].include?(bar)

  if bar >= 2 && bar < 4
    in_thread { percussion_one_bar source_measure.odd? }
  elsif bar >= 4 && bar < 6
    in_thread { percussion_one_bar source_measure.odd? }
    in_thread { filter_house_drums_bar :hats, false, 0.025 }
  elsif bar >= 6
    in_thread { filter_house_drums_bar :filtered_kick, false, 0.030 }
  end

  if [5, 7].include?(bar)
    in_thread { remix_stabs_bar chord_notes, 0.075, 88, 0.14 }
  end
  sleep 4
end

# 1:40-2:12: delayed drop, half-time reset, climax, and stutter.
cue :section_lead_stage_two
lead_stage_two_bars.times do |bar|
  source_measure = 33 + (bar % 8)
  phrase_bar = bar % 4
  chord_notes = remix_chords[bar % 4]

  if bar == 15
    in_thread { transition_stutter_bar lower_lead[phrase_bar] }
  else
    in_thread { tapping_bar lower_lead[phrase_bar] }
    in_thread { remix_lead_double lower_lead[phrase_bar], 0.09, 102 }
    in_thread do
      if bar < 8
        bass_amp = 0.235
        bass_cutoff = 61
      elsif bar < 12
        bass_amp = 0.215
        bass_cutoff = 58
      else
        bass_amp = 0.245
        bass_cutoff = 64
      end
      opening_bass_bar source_measure - 29, bass_amp, bass_cutoff
    end

    unless [8, 9].include?(bar)
      in_thread do
        funk_melody_bar [36, 40].include?(source_measure),
          :under_lead, 3, phrase_bar
      end
    end

    if (bar >= 2 && bar < 8) || (bar >= 12 && bar < 15)
      in_thread do
        remix_opening_sub_bar source_measure - 29, :under_lead
      end
    end

    in_thread { lead_effect_bar lower_lead[phrase_bar] } if [5, 7, 12, 14].include?(bar)
    in_thread { opening_synth_accent_bar false, 0.17 } if bar == 13

    if bar == 0
      in_thread { delayed_drop_drums_bar }
    elsif bar < 4
      in_thread { percussion_one_bar source_measure.odd? }
      in_thread { club_kick_bar 0.23, false }
    elsif bar < 8
      in_thread { percussion_two_bar }
      in_thread { club_kick_bar 0.24, false }
    elsif bar < 12
      in_thread { half_time_drums_bar }
    else
      in_thread { percussion_two_bar }
      in_thread { club_kick_bar 0.27, false }
    end

    if [4, 6, 12, 14].include?(bar)
      stab_amp = bar >= 12 ? 0.14 : 0.10
      stab_cutoff = bar >= 12 ? 98 : 86
      in_thread do
        remix_stabs_bar chord_notes, stab_amp, stab_cutoff, 0.14
      end
    elsif [5, 7, 10, 13].include?(bar)
      pad_amp = bar >= 12 ? 0.10 : (bar >= 8 ? 0.075 : 0.065)
      pad_cutoff = bar >= 12 ? 94 : (bar >= 8 ? 84 : 82)
      pad_pan = phrase_bar.even? ? -0.05 : 0.05
      in_thread do
        remix_pad_bar chord_notes, pad_amp, pad_cutoff, true, pad_pan
      end
    end
  end

  sleep 4
end

# 2:12-2:18: one bell, one bar of space, then a short atmospheric bed.
cue :section_transition_bell
church_bell
in_thread do
  sleep 4
  short_transition_bed
end
sleep transition_wait_beats

# 2:18-2:42: three melody passes; the last beat is silent.
cue :section_post_bell_melody_only
(post_melody_only_bars / 4).times do |pass|
  4.times do |bar|
    chord_notes = remix_chords[bar]
    final_cut_bar = pass == 2 && bar == 3
    primary_cutoff = [94, 100, 104][pass]
    harmonic_cutoff = [90, 96, 100][pass]
    pan_width = [0.08, 0.10, 0.12][pass]
    harmonic_scale = [1.00, 0.97, 0.94][pass]

    if final_cut_bar
      in_thread do
        post_synth_cut_bar bar, 3.0, primary_cutoff,
          harmonic_cutoff, harmonic_scale, pan_width
      end
    else
      in_thread do
        with_fx :pan, pan: -pan_width do
          post_synth_bar bar, false, 4.0, primary_cutoff, 1.0
        end
      end
      in_thread do
        with_fx :pan, pan: pan_width do
          post_synth_bar bar, true, 4.0,
            harmonic_cutoff, harmonic_scale
        end
      end
    end

    if pass == 1 && [0, 2].include?(bar)
      pad_pan = bar == 0 ? -0.05 : 0.05
      in_thread do
        remix_pad_bar chord_notes, 0.05, 80, false, pad_pan
      end
    elsif pass == 2 && bar == 1
      in_thread do
        remix_pad_bar chord_notes, 0.055, 80, false, 0.05
      end
    end

    if pass == 2 && [0, 2].include?(bar)
      in_thread do
        with_fx :pan, pan: 0.14 do
          post_primary_double_bar bar, 0.05
        end
      end
    end

    sleep 4
  end
end

# 2:42-3:18: half-time, club peak, and a sparse two-bar exit.
cue :section_post_bell_layered
post_layered_bars.times do |layered_bar|
  bar_index = layered_bar % 4
  chord_notes = remix_chords[bar_index]

  if layered_bar < 4
    primary_cutoff = 96
    harmonic_cutoff = 92
    pan_width = 0.10
  elsif layered_bar < 8
    primary_cutoff = 100
    harmonic_cutoff = 96
    pan_width = 0.12
  elsif layered_bar < 12
    primary_cutoff = 104
    harmonic_cutoff = 100
    pan_width = 0.14
  elsif layered_bar < 16
    primary_cutoff = 106
    harmonic_cutoff = 102
    pan_width = 0.16
  elsif layered_bar == 18
    primary_cutoff = 98
    harmonic_cutoff = 94
    pan_width = 0.10
  else
    primary_cutoff = 94
    harmonic_cutoff = 90
    pan_width = 0.08
  end

  if layered_bar == 16
    in_thread { beat_only_bar :filtered_kick, 0.03, false }
  elsif layered_bar == 17
    in_thread { sparse_deconstruction_drums_bar }
  elsif layered_bar == 19
    # The final beat is silent before the dedicated A-D ending decay.
    in_thread do
      post_synth_cut_bar bar_index, 3.0, primary_cutoff,
        harmonic_cutoff, 1.0, pan_width
    end
  else
    in_thread do
      with_fx :pan, pan: -pan_width do
        post_synth_bar bar_index, false, 4.0,
          primary_cutoff, 1.0
      end
    end
    in_thread do
      with_fx :pan, pan: pan_width do
        post_synth_bar bar_index, true, 4.0,
          harmonic_cutoff, 1.0
      end
    end
    in_thread { post_bass_bar }

    if [12, 14].include?(layered_bar)
      in_thread { post_sub_bar }
    end

    if layered_bar < 4
      in_thread { half_time_drums_bar }
    elsif layered_bar < 8
      in_thread { post_hihat_bar 0.18, 0.015, bar_index }
      in_thread { post_drums_bar }
    elsif layered_bar < 12
      in_thread { post_hihat_bar 0.19, 0.020, bar_index }
      in_thread { post_backbeat_bar }
      in_thread { club_kick_bar 0.22, false }
    elsif layered_bar < 16
      in_thread { post_hihat_bar 0.21, 0.025, bar_index }
      in_thread { post_backbeat_bar }
      in_thread { club_kick_bar 0.25, false }
    elsif layered_bar == 18
      in_thread { half_time_drums_bar }
    end

    if [2, 3].include?(layered_bar)
      in_thread { post_effect_chord_bar bar_index, false }
    elsif [4, 6].include?(layered_bar)
      in_thread { post_effect_chord_bar bar_index, true }
    end

    if [8, 10, 12, 14].include?(layered_bar)
      pad_amp = layered_bar >= 12 ? 0.10 : 0.08
      cutoff_value = layered_bar >= 12 ? 94 : 86
      pad_pan = bar_index == 0 ? -0.05 : 0.05
      in_thread do
        remix_pad_bar chord_notes, pad_amp, cutoff_value,
          true, pad_pan
      end
    elsif [9, 11, 13, 15].include?(layered_bar)
      stab_amp = layered_bar >= 12 ? 0.14 : 0.10
      cutoff_value = layered_bar >= 12 ? 94 : 86
      in_thread do
        remix_stabs_bar chord_notes, stab_amp,
          cutoff_value + 4, 0.16
      end
    end

    if layered_bar == 14
      in_thread do
        with_fx :pan, pan: 0.14 do
          post_primary_double_bar bar_index, 0.055
        end
      end
    end
  end

  sleep 4
end

# 3:18-3:26: a compact callback to the opening groove and its subtraction.
cue :section_opening_callback
opening_callback_bars.times do |bar|
  source_measure = 13 + bar

  if bar < 3
    callback_bass_amps = [0.225, 0.220, 0.205]
    callback_bass_cutoffs = [58, 58, 56]

    in_thread do
      funk_melody_bar false, :front, 3, bar
    end
    in_thread do
      opening_bass_bar source_measure - 9,
        callback_bass_amps[bar], callback_bass_cutoffs[bar]
    end
    in_thread { simple_primary_drums_bar } if bar == 1
  else
    in_thread { simple_lead_entry_bar }
  end

  sleep 4
end

# 3:26-3:28: short A-D decay followed by one second of true silence.
cue :section_final_decay
ending_decay_bar final_transition_beats

# 3:28: one unobstructed bell; five beats allow its 3.8-beat release.
cue :section_final_bell
final_church_bell
sleep 5

cue :arrangement_complete
