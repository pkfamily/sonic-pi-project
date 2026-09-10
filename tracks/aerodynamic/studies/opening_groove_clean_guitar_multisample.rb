# Aerodynamic opening-groove clean electric guitar multisample study
#
# Uses the local-only FreePats Electric Guitar FSBS Clean #1 samples documented
# in docs/aerodynamic-opening-groove-samples.md. The working clavinet sampler's
# phrase, timing, fills, event levels, and twenty-bar span are unchanged.

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

# The SFZ contains two velocity layers and four alternate takes per region.
# A3 and B3 share its B3 region; D4 uses the adjacent C-sharp4 region.
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
  }
}

guitar_note_map = {
  a3: :b3,
  b3: :b3,
  d4: :cs4
}

# Validate and preload only the sixteen source files used by this phrase.
guitar_source_map.each_value do |source_data|
  [:soft, :firm].each do |layer_name|
    source_data[layer_name].each do |sample_file|
      sample_path = guitar_sample_root + "/" + sample_file
      raise "Missing clean-guitar sample: " + sample_path unless File.exist?(sample_path)
      load_sample sample_path
    end
  end
end

define :play_clean_guitar_note do |pitch, level, phrase_gain, release_value,
    sample_root, note_map, source_map|
  source_key = note_map[pitch]
  source_data = source_map[source_key]

  # The original SFZ switches from soft to firm at MIDI velocity 93. Existing
  # phrase levels map to velocity targets 50, 85, and 115; only the highest
  # accents therefore select the firm recordings.
  velocity_target = if level < 0.75
    50
  elsif level < 1.05
    85
  else
    115
  end
  layer_name = velocity_target < 93 ? :soft : :firm
  sample_files = source_data[layer_name]

  # Cycle each target pitch independently so repeated notes do not machine-gun.
  tick_key = ("clean_guitar_" + pitch.to_s).to_sym
  take_index = tick(tick_key) % sample_files.length
  sample_path = sample_root + "/" + sample_files[take_index]
  source_pitch = note source_data[:source_pitch]
  target_pitch = note pitch
  rate_value = 2 ** ((target_pitch - source_pitch) / 12.0)

  sample sample_path, rate: rate_value, attack: 0.002, sustain: 0,
    release: release_value, amp: 0.46 * level * phrase_gain
end

define :clean_guitar_groove_bar do |fill_bar, phrase_position, sample_root,
    note_map, source_map|
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

  events.each do |event|
    onset = event[0].to_f
    sleep onset - cursor if onset > cursor
    play_clean_guitar_note event[1], event[2], phrase_gain, event[3],
      sample_root, note_map, source_map
    cursor = onset
  end

  sleep 4.0 - cursor if cursor < 4.0
end

tick_reset_all

20.times do |bar|
  source_measure = if bar < 12
    9 + (bar % 4)
  else
    13 + ((bar - 12) % 4)
  end
  clean_guitar_groove_bar [12, 16].include?(source_measure), bar % 4,
    guitar_sample_root, guitar_note_map, guitar_source_map
end
