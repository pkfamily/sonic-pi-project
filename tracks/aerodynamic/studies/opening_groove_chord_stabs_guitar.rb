# Aerodynamic opening-groove sampled guitar chord-stab study
#
# Twelve-bar A/B excerpt derived from opening_groove_chord_stabs_synth.rb.
# It preserves absolute opening bars 9-20 while replacing only the dpulse
# chord stabs with strummed FreePats clean-guitar multisamples.

use_bpm 120
use_debug false

# Set SONIC_PI_PROJECT_ROOT when the repository is cloned somewhere else.
project_root = ENV["SONIC_PI_PROJECT_ROOT"]
if project_root.nil? || project_root.empty?
  project_root = File.expand_path("~/Downloads/Repos/sonic-pi-project")
end
guitar_sample_root = File.join project_root,
  "tracks/aerodynamic/references/local_samples/electric_guitar",
  "EGuitarFSBS-clean SFZ+FLAC-20260807/samples/bridge"

guitar_source_map = {
  b3: {
    source_pitch: :b3,
    soft: [
      "B3_s5_soft_01.flac", "B3_s5_soft_02.flac",
      "B3_s5_soft_03.flac", "B3_s5_soft_04.flac"
    ],
    firm: [
      "B3_s5_01.flac", "B3_s5_02.flac",
      "B3_s5_03.flac", "B3_s5_04.flac"
    ]
  },
  cs4: {
    source_pitch: :cs4,
    soft: [
      "C#4_s5_soft_01.flac", "C#4_s5_soft_02.flac",
      "C#4_s5_soft_03.flac", "C#4_s5_soft_04.flac"
    ],
    firm: [
      "C#4_s5_01.flac", "C#4_s5_02.flac",
      "C#4_s5_03.flac", "C#4_s5_04.flac"
    ]
  },
  e4: {
    source_pitch: :e4,
    soft: [
      "E4_s6_soft_01.flac", "E4_s6_soft_02.flac",
      "E4_s6_soft_03.flac", "E4_s6_soft_04.flac"
    ],
    firm: [
      "E4_s6_01.flac", "E4_s6_02.flac",
      "E4_s6_03.flac", "E4_s6_04.flac"
    ]
  },
  g4: {
    source_pitch: :g4,
    soft: nil,
    firm: [
      "G4_s6_01.flac", "G4_s6_02.flac",
      "G4_s6_03.flac", "G4_s6_04.flac"
    ]
  }
}

guitar_note_map = {
  a3: :b3,
  b3: :b3,
  cs4: :cs4,
  d4: :cs4,
  e4: :e4,
  gs4: :g4
}

# Validate and preload the twenty-eight unique files used by the excerpt.
guitar_source_map.each_value do |source_data|
  [:soft, :firm].each do |layer_name|
    sample_files = source_data[layer_name]
    next unless sample_files
    sample_files.each do |sample_file|
      sample_path = guitar_sample_root + "/" + sample_file
      raise "Missing clean-guitar sample: " + sample_path unless File.exist?(sample_path)
      load_sample sample_path
    end
  end
end

# Play one four-beat bar of timestamped tonal events.
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
      play_chord notes, attack: 0.01, sustain: 0,
        release: duration * 0.82, cutoff: cutoff_value,
        amp: base_amp * level
    else
      play notes, attack: 0.01, sustain: 0,
        release: duration * 0.82, cutoff: cutoff_value,
        amp: base_amp * level
    end
    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

define :polished_drum_hit do |sample_name, amp_value, pan_value|
  if [:bd_ada, :bd_haus].include?(sample_name)
    gain_scale = 0.90
    release_value = 0.45
  elsif [:sn_dub, :drum_snare_hard].include?(sample_name)
    gain_scale = 0.82
    release_value = 0.32
  elsif [:drum_cymbal_pedal, :drum_cymbal_closed].include?(sample_name)
    gain_scale = 0.68
    release_value = 0.10
  elsif [:drum_cymbal_open, :drum_splash_soft].include?(sample_name)
    gain_scale = 0.68
    release_value = 0.50
  else
    gain_scale = 0.80
    release_value = 0.25
  end

  sample sample_name, amp: amp_value * gain_scale, pan: pan_value,
    sustain: 0, release: release_value
end

define :drum_bar do |events|
  cursor = 0.0
  events.each do |event|
    onset = event[0].to_f
    hits = event[1]
    sleep onset - cursor if onset > cursor
    hits.each do |hit|
      hit_pan = hit.length > 2 ? hit[2] : 0
      polished_drum_hit hit[0], hit[1], hit_pan
    end
    cursor = onset
  end
  sleep 4.0 - cursor if cursor < 4.0
end

define :play_clean_guitar_note do |pitch, level, phrase_gain, release_value,
    take_index, sample_root, note_map, source_map|
  source_key = note_map[pitch]
  source_data = source_map[source_key]
  velocity_target = if level < 0.75
    50
  elsif level < 1.05
    85
  else
    115
  end
  layer_name = velocity_target < 93 ? :soft : :firm
  sample_files = source_data[layer_name]
  take_order = [0, 2, 3, 1]
  sample_file = sample_files[take_order[take_index % take_order.length]]
  sample_path = sample_root + "/" + sample_file
  source_pitch = note source_data[:source_pitch]
  target_pitch = note pitch
  rate_value = 2 ** ((target_pitch - source_pitch) / 12.0)

  sample sample_path, rate: rate_value, attack: 0.002, sustain: 0,
    release: release_value, amp: 0.46 * level * phrase_gain
end

# One exact V10 funk-melody bar using the approved clean-guitar source.
define :clean_guitar_groove_bar do |fill_bar, phrase_position, opening_bar,
    sample_root, note_map, source_map|
  events = [
    [0.5, :d4, 1.12, 0.22],
    [1.0, :b3, 0.84, 0.11]
  ]
  events.push [1.25, :a3, 0.66, 0.11] if fill_bar
  events.concat [
    [2.0, :a3, 1.00, 0.11],
    [2.25, :b3, 0.76, 0.11],
    [2.5, :d4, 1.18, 0.22],
    [3.0, :b3, 0.88, 0.11]
  ]

  phrase_gains = [0.96, 1.00, 0.98, 1.04]
  phrase_gain = phrase_gains[phrase_position % 4]
  cursor = 0.0

  events.each_with_index do |event, event_index|
    onset = event[0].to_f
    sleep onset - cursor if onset > cursor
    take_index = (opening_bar * 7) + event_index
    play_clean_guitar_note event[1], event[2], phrase_gain, event[3],
      take_index, sample_root, note_map, source_map
    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

define :opening_bass_bar do |bar_index, amp_value, cutoff_value|
  if bar_index.even?
    events = [
      [0.0, 1.0, :b2, 1.0],
      [1.5, 0.5, :b2, 1.0],
      [3.5, 0.5, :fs2, 1.0]
    ]
  else
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
  tonal_bar events, :tb303, amp_value * 0.88, cutoff_value
end

define :opening_synth_accent_bar do |full_bar, amp_value|
  events = [[0.5, 0.5, :a3, 1.0]]
  if full_bar
    events.push [1.25, 0.5, :a3, 0.82]
    events.push [2.0, 0.25, :a3, 0.9]
  end
  tonal_bar events, :prophet, amp_value, 98
end

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

remix_chords = [
  [:b3, :d4, :fs4],
  [:b3, :e4, :gs4],
  [:b3, :e4, :g4],
  [:a3, :cs4, :e4]
]

define :remix_opening_sub_bar do |bar_index|
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
  tonal_bar events, :sine, 0.045, 72
end

define :play_guitar_stab_note do |pitch, layer_name, amp_value, pan_value,
    take_index, sample_root, note_map, source_map|
  source_key = note_map[pitch]
  source_data = source_map[source_key]
  # The G4 region has no soft layer, so its response uses a quieter firm take.
  sample_files = source_data[layer_name] || source_data[:firm]
  take_order = [0, 2, 3, 1]
  sample_file = sample_files[take_order[take_index % take_order.length]]
  sample_path = sample_root + "/" + sample_file
  source_pitch = note source_data[:source_pitch]
  target_pitch = note pitch
  rate_value = 2 ** ((target_pitch - source_pitch) / 12.0)

  sample sample_path, rate: rate_value, attack: 0.002, sustain: 0,
    release: 0.18, hpf: 50, amp: amp_value, pan: pan_value
end

# Two realistic guitar chops at the original nominal stab onsets. The first is
# a firm downstroke; the quieter response reverses its order like an upstroke.
define :remix_stabs_bar do |chord_notes, stab_number, sample_root, note_map,
    source_map|
  hits = [
    [1.5, chord_notes, :firm, 0.38, -0.10],
    [3.5, chord_notes.reverse, :soft, 0.30, 0.10]
  ]
  cursor = 0.0

  hits.each_with_index do |hit, hit_index|
    onset = hit[0].to_f
    strum_notes = hit[1]
    sleep onset - cursor if onset > cursor

    strum_notes.each_with_index do |pitch, note_index|
      take_index = (stab_number * 2) + (hit_index * 3) + note_index
      play_guitar_stab_note pitch, hit[2], hit[3], hit[4], take_index,
        sample_root, note_map, source_map
      sleep 0.02 if note_index < strum_notes.length - 1
    end
    cursor = onset + 0.04
  end

  sleep 4.0 - cursor if cursor < 4.0
end

define :remix_pad_bar do |chord_notes, amp_value, cutoff_value, pan_value|
  use_synth :hollow
  effective_amp = amp_value * 0.75
  effective_cutoff = [cutoff_value, 88].min
  with_fx :slicer, phase: 1, wave: 0, invert_wave: 1,
      amp_min: 0.45, amp_max: 1, smooth: 0.02, mix: 0.55 do
    play_chord chord_notes, attack: 0.15, sustain: 3.15,
      release: 0.28, cutoff: effective_cutoff, amp: effective_amp,
      pan: pan_value
    sleep 4
  end
end

define :filter_house_drums_bar do |stage, swing_amount|
  events = []
  closed_amp = 0.11
  kick_amp = stage == :filtered_kick ? 0.21 : 0.25

  [0.5, 1.5, 2.5, 3.5].each_with_index do |onset, index|
    pan_value = index.even? ? -0.22 : 0.22
    timed_onset = onset + (index.odd? ? swing_amount : 0)
    hat_level = [0.90, 1.00, 0.94, 1.05][index]
    events.push [timed_onset, :drum_cymbal_closed,
      closed_amp * hat_level, pan_value, nil]
  end

  if stage == :filtered_kick
    4.times do |beat|
      events.push [beat.to_f, :bd_haus, kick_amp, 0, 42]
    end
  end

  events = events.sort_by { |event| event[0] }
  cursor = 0.0
  events.each do |event|
    onset = event[0].to_f
    sleep onset - cursor if onset > cursor
    if event[4]
      with_fx :hpf, cutoff: event[4] do
        polished_drum_hit event[1], event[2], event[3]
      end
    else
      polished_drum_hit event[1], event[2], event[3]
    end
    cursor = onset
  end
  sleep 4.0 - cursor if cursor < 4.0
end

define :club_kick_bar do |amp_value|
  events = []
  4.times do |beat|
    events.push [beat.to_f, [[:bd_haus, amp_value * 0.85]]]
  end
  drum_bar events
end

# V10's one-beat supplemental chop, retained as a quiet arrangement layer.
define :funk_micro_chop_bar do |amp_value|
  use_synth :pluck
  sleep 3
  [:d4, :b3, :a3, :b3].each_with_index do |pitch, note_index|
    pan_value = note_index.even? ? -0.08 : 0.08
    play pitch, attack: 0.002, sustain: 0, release: 0.075,
      cutoff: 96, amp: amp_value, pan: pan_value
    sleep 0.25
  end
end

# Absolute opening bars 9-20 preserve all six stab bars and three complete
# four-bar phrases while this study's local timeline remains exactly 48 beats.
cue :section_chord_stabs_guitar

with_fx :level, amp: 0.90 do
  (8...20).each do |bar|
    source_measure = if bar < 12
      9 + (bar % 4)
    else
      13 + ((bar - 12) % 4)
    end

    chord_notes = remix_chords[bar % 4]
    bass_amp = bar < 16 ? 0.255 : 0.265
    bass_cutoff = bar < 16 ? 62 : 64

    in_thread do
      clean_guitar_groove_bar [12, 16].include?(source_measure), bar % 4,
        bar, guitar_sample_root, guitar_note_map, guitar_source_map
    end
    in_thread do
      opening_bass_bar source_measure - 9, bass_amp, bass_cutoff
    end
    in_thread { remix_opening_sub_bar source_measure - 9 }
    in_thread { percussion_one_bar source_measure.odd? } if bar < 16

    if [11, 15, 19].include?(bar)
      in_thread do
        opening_synth_accent_bar [12, 16].include?(source_measure), 0.18
      end
    end

    in_thread { percussion_two_bar } if bar >= 16

    if bar < 12
      in_thread { filter_house_drums_bar :filtered_kick, 0.025 }
    elsif bar < 16
      in_thread { club_kick_bar 0.20 }
    else
      in_thread { club_kick_bar 0.22 }
    end

    if [9, 11, 13, 15, 17, 19].include?(bar)
      stab_number = (bar - 9) / 2
      in_thread do
        remix_stabs_bar chord_notes, stab_number, guitar_sample_root,
          guitar_note_map, guitar_source_map
      end
    end

    if [16, 18].include?(bar)
      pad_pan = bar % 4 == 0 ? -0.05 : 0.05
      in_thread { remix_pad_bar chord_notes, 0.06, 86, pad_pan }
    end

    in_thread { funk_micro_chop_bar 0.14 } if bar == 11
    sleep 4
  end
end

cue :arrangement_complete
