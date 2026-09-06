# Aerodynamic-style arrangement with explicit phase cues.
# Every section starts and ends on the master timeline.

use_bpm 123
set :post_section, false

define :lead_sequence do
  use_synth :zawa
  use_synth_defaults attack: 0.05, sustain: 0.15, release: 0.125, amp: 0.55
  [[:d4, :fs3, :b3, :fs3], [:d4, :gs3, :b3, :gs3],
   [:g4, :b3, :e4, :b3], [:e4, :a3, :cs4, :a3],
   [:d4, :fs4, :b3, :fs4], [:d4, :gs4, :b3, :gs4],
   [:g4, :b3, :e4, :b3], [:e4, :a3, :cs4, :a3]].each do |notes|
    4.times do
      notes.each do |n|
        stop if get(:post_section)
        play n
        sleep 0.25
      end
    end
  end
end

define :opening_melody do
  use_synth :pluck
  2.times do
    stop if get(:post_section)
    sleep 0.5; play :d4, amp: 0.55; sleep 0.5
    stop if get(:post_section)
    play :b3, amp: 0.55; sleep 1
    stop if get(:post_section)
    play :a3, amp: 0.55; sleep 0.25
    stop if get(:post_section)
    play :b3, amp: 0.55; sleep 0.25
    stop if get(:post_section)
    play :d4, amp: 0.55; sleep 0.5
    stop if get(:post_section)
    play :b3, amp: 0.55; sleep 1
  end
end

define :opening_bass do
  use_synth :tb303
  stop if get(:post_section)
  play :b2, release: 0.35, cutoff: 60, amp: 0.3; sleep 1.5
  stop if get(:post_section)
  play :b2, release: 0.4, cutoff: 62, amp: 0.3; sleep 2
  stop if get(:post_section)
  play :fs2, release: 0.35, cutoff: 60, amp: 0.3; sleep 0.5
  stop if get(:post_section)
  play :g2, release: 0.35, cutoff: 60, amp: 0.3; sleep 1.5
  stop if get(:post_section)
  play_chord [:e2, :b2], release: 0.4, cutoff: 62, amp: 0.24; sleep 2
  stop if get(:post_section)
  play :fs2, release: 0.35, cutoff: 60, amp: 0.3; sleep 0.5
end

define :opening_percussion do
  2.times do
    sample :bd_ada, amp: 0.7; sleep 0.75
    sample :bd_ada, amp: 0.35; sleep 0.25
    sample :sn_dub, amp: 0.55; sleep 0.5
    sample :bd_ada, amp: 0.4; sleep 1.5
    sample :sn_dub, amp: 0.55; sleep 0.5
    sample :bd_ada, amp: 0.35; sleep 0.5
  end
end

define :opening_phrase do
  in_thread { opening_bass }
  in_thread { opening_melody }
  in_thread { opening_percussion }
  use_synth :pluck
  16.times do |i|
    play [[:d6, :fs5], [:d6, :gs5], [:g6, :e6], [:e6, :d6]][i % 4],
      release: 0.16, cutoff: 115, amp: [1.25, 0.82, 1.05, 0.88][i % 4]
    sleep 0.5
  end
end

# Lead exists before the master starts, but cannot play until cued.
in_thread do
  sync :lead_start
  3.times { lead_sequence }
  cue :support_start
  loop do
    stop if get(:post_section)
    lead_sequence
  end
end

# Support layers are also explicitly cued after the lead-only phase.
in_thread do
  sync :support_start
  loop do
    stop if get(:post_section)
    in_thread { opening_bass }
    in_thread { opening_melody }
    sleep 8
  end
end

# GP4 post-lead transition: four bell bars, then the new four-bar melody.
in_thread do
  sync :support_start
  sleep 32

  # Stop the lead/support threads before the transition bell is struck.
  set :post_section, true

  use_synth :pretty_bell
  play_chord [:e4, :b4, :e5, :g5], release: 4.5, amp: 1.1
  sleep 8

  melody = [
    [[:d4, :fs3, :b3, :fs3, :d4, :b3], [:d4, :e4, :d4, :cs4]],
    [[:b3, :e3, :gs3, :e3, :b3, :gs3], [:b3, :cs4, :b3, :a3]],
    [[:b3, :d3, :g3, :d3, :b3, :g3], [:cs4, :d4, :cs4, :b3]],
    [[:cs4, :e3, :a3, :e3, :e4, :cs4], [:a4, :e4]]
  ]

  use_synth :prophet
  3.times do
    melody.each do |bar|
      bar[0].each do |note|
        play note, release: 0.18, cutoff: 100, amp: 0.52
        sleep 0.5
      end
      bar[1].each do |note|
        play note, release: 0.14, cutoff: 108, amp: 0.58
        sleep 0.25
      end
      sleep 0.5 if bar == melody.last
    end
  end
end

# Master timeline.
in_thread do
  with_fx :reverb, room: 1, mix: 0.75 do
    4.times do
      use_synth :sine
      play :e3, release: 4.8, amp: 1.0
      use_synth :pretty_bell
      play_chord [:e4, :b4, :e5, :g5], release: 4.5, amp: 1.15
      sleep 4
    end
  end

  8.times { opening_phrase }
  cue :lead_start
end
