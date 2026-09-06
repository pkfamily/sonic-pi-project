# Timestamp-matched Aerodynamic arrangement derived from ../references/aerodynamic.gp4.
#
# Hybrid choices retained from the working version:
# - four opening bells, one strike per bar
# - one transition bell followed by an eight-beat interval
# - three passes of the post-bell melody
#
# All other pitches, rests, rhythms, and layer entrances follow the GP4.

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

# GP4 Melodie: measures 9-16 and 29-40.
define :opening_melody_bar do |fill_bar|
  events = [
    [0.5, 0.5, :d4, 1.0],
    [1.0, 0.25, :b3, 1.0]
  ]
  events.push [1.25, 0.25, :a3, 1.0] if fill_bar
  events.concat [
    [2.0, 0.25, :a3, 1.0],
    [2.25, 0.25, :b3, 1.0],
    [2.5, 0.5, :d4, 1.0],
    [3.0, 0.25, :b3, 1.0]
  ]
  tonal_bar events, :pluck, 0.58, 112
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
define :post_effect_chord_bar do |bar_index|
  chords = [
    [:d4, :b3, :fs3, :b2],
    [:b3, :gs3, :e3, :b2, :gs2],
    [:b3, :g3, :e3, :b2, :e2],
    [:cs4, :g3, :e3, :a2]
  ]
  use_synth :dsaw
  play_chord chords[bar_index], attack: 0.08, sustain: 3.45,
    release: 0.4, cutoff: 82, amp: 0.17
  sleep 4
end

# -----------------------------------------------------------------------------
# Timestamp-matched finite master timeline
# At 120 BPM in 4/4, each four-beat bar lasts exactly two seconds.
# -----------------------------------------------------------------------------

opening_bell_bars = 8
opening_groove_bars = 22
lead_only_bars = 16
lead_stage_one_bars = 8
lead_stage_two_bars = 16
transition_wait_beats = 16
post_melody_only_bars = 12
post_layered_bars = 16

# 0:00-0:16: four bells at 0:00, 0:04, 0:08, and 0:12.
cue :section_opening_bells
opening_bell_bars.times do |bar|
  church_bell if bar.even?
  sleep 4
end

# 0:16-1:00: extended opening groove.
# Stage one is measures 9-12 x3; stage two is measures 13-16 x2 + 13-14.
cue :section_opening_groove
opening_groove_bars.times do |bar|
  if bar < 12
    source_measure = 9 + (bar % 4)
  else
    source_measure = 13 + ((bar - 12) % 4)
  end

  in_thread do
    opening_melody_bar [12, 16].include?(source_measure)
  end
  in_thread { opening_bass_bar source_measure - 9 }
  in_thread { percussion_one_bar source_measure.odd? }

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar [12, 16].include?(source_measure)
    end
  end

  # The heavier GP4 percussion layer enters for the final ten bars.
  in_thread { percussion_two_bar } if bar >= 12
  sleep 4
end

lower_lead = [
  [:d4, :fs3, :b3, :fs3],
  [:d4, :gs3, :b3, :gs3],
  [:g4, :b3, :e4, :b3],
  [:e4, :a3, :cs4, :a3]
]
upper_lead = [
  [:d5, :fs4, :b4, :fs4],
  [:d5, :gs4, :b4, :gs4],
  [:g5, :b4, :e5, :b4],
  [:e5, :a4, :cs5, :a4]
]

# 1:00-1:32: sixteen bars of lead with no supporting layers.
cue :section_lead_only
lead_only_bars.times do |bar|
  phrase_bar = bar % 4
  lead_notes = bar < 8 ? lower_lead[phrase_bar] : upper_lead[phrase_bar]
  in_thread { tapping_bar lead_notes }
  sleep 4
end

# 1:32-1:48: GP4 measures 29-32 repeated twice.
# Lead + first-stage groove; the heavy percussion remains absent.
cue :section_lead_stage_one
lead_stage_one_bars.times do |bar|
  source_measure = 29 + (bar % 4)
  phrase_bar = bar % 4

  in_thread { tapping_bar upper_lead[phrase_bar] }
  in_thread { lead_effect_bar lower_lead[phrase_bar] }
  in_thread do
    opening_melody_bar source_measure == 32
  end
  in_thread { opening_bass_bar source_measure - 29 }
  in_thread { percussion_one_bar source_measure.odd? }

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar source_measure == 32
    end
  end

  sleep 4
end

# 1:48-2:20: GP4 measures 33-40 repeated twice.
# The complete heavier opening groove now plays over the lower lead.
cue :section_lead_stage_two
lead_stage_two_bars.times do |bar|
  source_measure = 33 + (bar % 8)
  phrase_bar = bar % 4

  in_thread { tapping_bar lower_lead[phrase_bar] }
  in_thread do
    opening_melody_bar [36, 40].include?(source_measure)
  end
  in_thread { opening_bass_bar source_measure - 29 }
  in_thread { percussion_one_bar source_measure.odd? }
  in_thread { percussion_two_bar }

  # Effets is absent in measures 33-36 and returns in measures 37-40.
  if source_measure >= 37
    in_thread { lead_effect_bar lower_lead[phrase_bar] }
  end

  if source_measure.even?
    in_thread do
      opening_synth_accent_bar [36, 40].include?(source_measure)
    end
  end

  sleep 4
end

# 2:20: every lead and groove bar has ended before this strike.
cue :section_transition_bell
church_bell

# Sixteen beats at 120 BPM equals the required eight-second interval.
sleep transition_wait_beats

# 2:28-2:52: three complete passes of the two-voice melody alone.
cue :section_post_bell_melody_only
(post_melody_only_bars / 4).times do
  4.times do |bar|
    in_thread { post_synth_bar bar, false }
    in_thread { post_synth_bar bar, true }
    sleep 4
  end
end

# 2:52-3:24: four complete passes with the GP4 rhythm section.
cue :section_post_bell_layered
(post_layered_bars / 4).times do
  4.times do |bar|
    in_thread { post_synth_bar bar, false }
    in_thread { post_synth_bar bar, true }
    in_thread { post_bass_bar }
    in_thread { post_hihat_bar }
    in_thread { post_drums_bar }
    in_thread { post_effect_chord_bar bar }
    sleep 4
  end
end

# 3:24: all melody and rhythm threads have ended; strike one final bell.
cue :section_final_bell
church_bell
sleep 5

cue :arrangement_complete
