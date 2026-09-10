# Aerodynamic opening-groove clavinet multisample study
#
# Uses the local-only No Budget Orchestra clavinet samples documented in
# docs/aerodynamic-opening-groove-samples.md. The V10 phrase, timing, fills,
# event levels, and twenty-bar opening-groove span are unchanged.

use_bpm 120
use_debug false

# Set SONIC_PI_PROJECT_ROOT when the repository is cloned somewhere else.
project_root = ENV["SONIC_PI_PROJECT_ROOT"]
if project_root.nil? || project_root.empty?
  project_root = File.expand_path("~/Downloads/Repos/sonic-pi-project")
end
clavinet_sample_root = File.join project_root,
  "tracks/aerodynamic/references/local_samples/clavinet/Clavinet"

# Mapping format: pitch => [sample filename, sample root pitch].
# Every target is within two semitones of its source recording.
clavinet_sample_map = {
  a3: ["4_Ab.wav", :gs3],
  b3: ["5_C.wav", :c4],
  d4: ["5_E.wav", :e4]
}

clavinet_sample_map.each_value do |sample_data|
  sample_path = clavinet_sample_root + "/" + sample_data[0]
  raise "Missing clavinet sample: " + sample_path unless File.exist?(sample_path)
end

define :play_clavinet_note do |pitch, level, phrase_gain, release_value,
    sample_root, sample_map|
  sample_data = sample_map[pitch]
  sample_path = sample_root + "/" + sample_data[0]
  source_pitch = note sample_data[1]
  target_pitch = note pitch
  rate_value = 2 ** ((target_pitch - source_pitch) / 12.0)

  sample sample_path, rate: rate_value, attack: 0.002, sustain: 0,
    release: release_value, amp: 0.58 * level * phrase_gain
end

define :clavinet_groove_bar do |fill_bar, phrase_position, sample_root,
    sample_map|
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
    play_clavinet_note event[1], event[2], phrase_gain, event[3],
      sample_root, sample_map
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
  clavinet_groove_bar [12, 16].include?(source_measure), bar % 4,
    clavinet_sample_root, clavinet_sample_map
end
