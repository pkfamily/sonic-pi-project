# Aerodynamic distorted-guitar plus zawa lead study
#
# Layers a restrained zawa transient over the FreePats FSBS Distorted #2
# multisample. The guitar remains the main voice; zawa follows the exact V11
# pitches and timing to add definition without restoring the old blade stack.
# The complete 1:04-2:12 lead arc remains isolated for direct A/B listening.

use_bpm 120
use_debug false

# Local-only source documented in docs/aerodynamic-lead-samples.md.
# Set SONIC_PI_PROJECT_ROOT when the repository is cloned somewhere else.
project_root = ENV["SONIC_PI_PROJECT_ROOT"]
if project_root.nil? || project_root.empty?
  project_root = File.expand_path("~/Downloads/Repos/sonic-pi-project")
end
distorted_sample_root = File.join project_root,
  "tracks/aerodynamic/references/local_samples/electric_guitar_distorted",
  "EGuitarFSBS-dist2 SFZ+FLAC-20220911/samples/bridge"

distorted_source_map = {
  g3: {
    source_pitch: :g3,
    soft: [
      "G3_s4_soft_01.flac", "G3_s4_soft_02.flac",
      "G3_s4_soft_03.flac", "G3_s4_soft_04.flac"
    ],
    firm: [
      "G3_s4_01.flac", "G3_s4_02.flac",
      "G3_s4_03.flac", "G3_s4_04.flac"
    ]
  },
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
    single: [
      "G4_s6_01.flac", "G4_s6_02.flac",
      "G4_s6_03.flac", "G4_s6_04.flac"
    ]
  }
}

distorted_note_map = {
  fs3: :g3,
  gs3: :g3,
  a3: :b3,
  b3: :b3,
  cs4: :cs4,
  d4: :cs4,
  e4: :e4,
  fs4: :g4,
  g4: :g4,
  gs4: :g4
}

# Validate and preload only the thirty-six recordings needed by this lead.
distorted_source_map.each_value do |source_data|
  [:soft, :firm, :single].each do |layer_name|
    sample_files = source_data[layer_name]
    next if sample_files.nil?

    sample_files.each do |sample_file|
      sample_path = distorted_sample_root + "/" + sample_file
      raise "Missing distorted-guitar sample: " + sample_path unless File.exist?(sample_path)
      load_sample sample_path
    end
  end
end

define :play_layered_lead_note do |pitch, absolute_bar, event_index,
    accented, release_value, sample_root, note_map, source_map|
  source_key = note_map[pitch]
  source_data = source_map[source_key]
  layer_name = if source_data[:single]
    :single
  elsif accented
    :firm
  else
    :soft
  end
  sample_files = source_data[layer_name]
  take_order = [0, 2, 3, 1]
  take_index = (absolute_bar * 16) + event_index
  sample_file = sample_files[take_order[take_index % 4]]
  sample_path = sample_root + "/" + sample_file
  source_pitch = note source_data[:source_pitch]
  target_pitch = note pitch
  rate_value = 2 ** ((target_pitch - source_pitch) / 12.0)
  sample_level = accented ? 1.40 : 1.23
  zawa_level = accented ? 0.13 : 0.11
  zawa_release = [release_value * 0.70, 0.025].max

  sample sample_path, rate: rate_value, attack: 0.001, sustain: 0,
    release: release_value, amp: sample_level
  synth :zawa, note: pitch, attack: 0.01, sustain: 0,
    release: zawa_release, cutoff: 96, phase: 0.25, amp: zawa_level
end

# One exact four-beat lead bar: a four-note sixteenth motif repeated four times.
define :layered_lead_bar do |notes, absolute_bar, sample_root, note_map,
    source_map|
  4.times do |repeat_index|
    notes.each_with_index do |pitch, note_index|
      event_index = (repeat_index * 4) + note_index
      accented = note_index == 0
      play_layered_lead_note pitch, absolute_bar, event_index, accented,
        0.20, sample_root, note_map, source_map
      sleep 0.25
    end
  end
end

# Three beats of the final motif followed by the accelerating D4 stutter.
define :layered_lead_stutter_bar do |notes, absolute_bar, sample_root,
    note_map, source_map|
  3.times do |repeat_index|
    notes.each_with_index do |pitch, note_index|
      event_index = (repeat_index * 4) + note_index
      accented = note_index == 0
      play_layered_lead_note pitch, absolute_bar, event_index, accented,
        0.20, sample_root, note_map, source_map
      sleep 0.25
    end
  end

  intervals = [0.5, 0.25, 0.125, 0.125]
  releases = [0.10, 0.07, 0.04, 0.03]
  intervals.each_with_index do |interval, index|
    play_layered_lead_note :d4, absolute_bar, 12 + index, false,
      releases[index], sample_root, note_map, source_map
    sleep interval
  end
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

absolute_bar = 0

cue :study_lead_only
12.times do |bar|
  phrase_bar = bar % 4
  lead_notes = bar < 8 ? lower_lead[phrase_bar] : upper_lead[phrase_bar]
  layered_lead_bar lead_notes, absolute_bar, distorted_sample_root,
    distorted_note_map, distorted_source_map
  absolute_bar += 1
end

cue :study_lead_stage_one
6.times do |bar|
  phrase_bar = bar % 4
  layered_lead_bar upper_lead[phrase_bar], absolute_bar,
    distorted_sample_root, distorted_note_map, distorted_source_map
  absolute_bar += 1
end

cue :study_lead_stage_two
15.times do |bar|
  phrase_bar = bar % 4
  layered_lead_bar lower_lead[phrase_bar], absolute_bar,
    distorted_sample_root, distorted_note_map, distorted_source_map
  absolute_bar += 1
end

cue :study_lead_stutter
layered_lead_stutter_bar lower_lead[3], absolute_bar,
  distorted_sample_root, distorted_note_map, distorted_source_map

cue :study_complete
