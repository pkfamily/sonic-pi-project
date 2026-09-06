# Corrected Sonic Pi version
# Put the WAV files in ~/Samples/ or change these paths.
use_bpm 123

# Reset the handoff state whenever the script is run again.
set :solo_started, false
set :lead_support, false
set :percussion_started, false
set :percussion_enabled, false
set :opening_bass_enabled, true
set :bass_muted, false
set :opening_layers_enabled, true

# Four bell hits that open the Aerodynamic-style section
in_thread do
  with_fx :reverb, room: 1, damp: 0.35, mix: 0.75 do
    4.times do
      # Low fundamental gives the bell its weight.
      use_synth :sine
      play :e3, attack: 0.01, release: 4.8, amp: 1.0

      # Upper partials add the metallic church-bell character.
      use_synth :pretty_bell
      play_chord [:e4, :b4, :e5, :g5], release: 4.5, amp: 1.15
      sleep 4
    end
  end
  cue :bells_done
end

# Keep the main arrangement silent until the bell introduction is complete.
sync :bells_done

maquillage = "~/Samples/il-macquillage-lady.wav"
aerodynamic = "~/Samples/funk.wav"

define :funk_phrase do
  # Alternate tab reading: four high dyadic shapes, repeated.
  main_beat = (ring [:d6, :fs5], [:d6, :gs5],
                    [:g6, :e6], [:e6, :d6])

  # Bass track extracted from the accessible GP4 arrangement.
  in_thread do
    use_synth :tb303
    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play :b2, release: 0.35, cutoff: 60, res: 0.65, amp: 0.2
    sleep 1.5
    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play :b2, release: 0.4, cutoff: 62, res: 0.65, amp: 0.2
    sleep 2
    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play :fs2, release: 0.35, cutoff: 60, res: 0.65, amp: 0.2
    sleep 0.5

    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play :g2, release: 0.35, cutoff: 60, res: 0.65, amp: 0.2
    sleep 1.5
    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play_chord [:e2, :b2], release: 0.4, cutoff: 62, res: 0.65, amp: 0.16
    sleep 2
    stop unless get(:opening_bass_enabled) && !get(:solo_started)
    play :fs2, release: 0.35, cutoff: 60, res: 0.65, amp: 0.2
    sleep 0.5
  end

  # GP4 Melodie track: the opening syncopated D4/B3/A3 figure.
  in_thread do
    use_synth :pluck
    stop unless get(:opening_layers_enabled)
    2.times do
      stop if get(:solo_started)
      sleep 0.5
      stop if get(:solo_started)
      play :d4, attack: 0.01, release: 0.22, amp: 0.42
      sleep 0.5
      stop if get(:solo_started)
      play :b3, attack: 0.01, release: 0.3, amp: 0.42
      sleep 1
      stop if get(:solo_started)
      play :a3, attack: 0.01, release: 0.3, amp: 0.42
      sleep 0.25
      stop if get(:solo_started)
      play :b3, attack: 0.01, release: 0.3, amp: 0.42
      sleep 0.25
      stop if get(:solo_started)
      play :d4, attack: 0.01, release: 0.22, amp: 0.42
      sleep 0.5
      stop if get(:solo_started)
      play :b3, attack: 0.01, release: 0.3, amp: 0.42
      sleep 1
    end
  end

  use_synth :pluck
  with_fx :distortion, distort: 0.08 do
    4.times do
      main_beat.each_with_index do |note, i|
      stop unless get(:opening_layers_enabled)
      stop if get(:solo_started)
        accent = [1.2, 0.72, 1.0, 0.78][i]
        play note, attack: 0.005, release: 0.16, cutoff: 115, amp: accent if note
        sleep 0.5
      end
    end
  end
end

in_thread do
  8.times do
    with_fx :ixi_techno, mix: 0.2, phase: 8, cutoff_min: 90, cutoff_max: 120, res: 0.9 do
      with_fx :bpf, mix: 0, res: 0.00001, centre: :b8 do
        funk_phrase
      end
    end
  end
  sleep 1
  cue :opening_done
end

define :play_lead_sequence do
  use_synth :zawa
  use_synth_defaults attack: 0.05, sustain: 0.15, release: 0.125, amp: 0.55
  phases = [[:d4,:fs3,:b3,:fs3],[:d4,:gs3,:b3,:gs3],[:g4,:b3,:e4,:b3],[:e4,:a3,:cs4,:a3],
            [:d4,:fs4,:b3,:fs4],[:d4,:gs4,:b3,:gs4],[:g4,:b3,:e4,:b3],[:e4,:a3,:cs4,:a3]]
  phases.each do |notes|
    4.times { notes.each { |pitch| play pitch; sleep 0.25 } }
  end
end

# One master timeline prevents the opening layers from racing the lead entrance.
in_thread do
  sync :opening_done
  set :solo_started, true
  set :opening_bass_enabled, false
  set :bass_muted, true
  set :opening_layers_enabled, false
  set :lead_support, false
  set :percussion_enabled, false
  # Full-bar clearance so the lead starts in the same context as lead_only.rb.
  sleep 4

  3.times { play_lead_sequence }
  set :bass_muted, false
  set :lead_support, true

  loop do
    play_lead_sequence
  end
end

# GP4 rebuild: the opening melody and bass return after 12 lead bars.
support_bar = 0
live_loop :lead_support do
  unless get(:lead_support)
    sleep 0.25
    next
  end

  unless get(:percussion_started)
    set :percussion_started, true
    set :percussion_enabled, true

    # GP4 Daft Percussion 1 enters with the bass and opening melody.
    in_thread do
      sleep 4
      loop do
        stop unless get(:percussion_enabled)
        sample :bd_ada, amp: 0.9
        sleep 0.75
        sample :bd_ada, amp: 0.45
        sleep 0.25
        sample :sn_dub, amp: 0.7
        sleep 0.5
        sample :bd_ada, amp: 0.55
        sleep 1.5
        sample :sn_dub, amp: 0.7
        sleep 0.5
        sample :bd_ada, amp: 0.45
        sleep 0.5
      end
    end

    # GP4 Daft Percussion 2 enters four bars after Percussion 1.
    in_thread do
      sleep 20
      loop do
        stop unless get(:percussion_enabled)
        16.times do |i|
          sample :drum_cymbal_closed, amp: (i % 4 == 0 ? 0.22 : 0.12), finish: 0.05
          sleep 0.25
        end
        sample :sn_dub, amp: 0.35
        sleep 4
      end
    end
  end

  if support_bar.even?
    in_thread do
      use_synth :tb303
      stop if get(:bass_muted)
      play :b2, release: 0.35, cutoff: 60, amp: 0.2
      sleep 1.5
      stop if get(:bass_muted)
      play :b2, release: 0.4, cutoff: 62, amp: 0.2
      sleep 2
      stop if get(:bass_muted)
      play :fs2, release: 0.35, cutoff: 60, amp: 0.2
      sleep 0.5
      stop if get(:bass_muted)
      play :g2, release: 0.35, cutoff: 60, amp: 0.2
      sleep 1.5
      stop if get(:bass_muted)
      play_chord [:e2, :b2], release: 0.4, cutoff: 62, amp: 0.16
      sleep 2
      stop if get(:bass_muted)
      play :fs2, release: 0.35, cutoff: 60, amp: 0.2
    end
  end

  use_synth :pluck
  play_pattern_timed [:d4, :b3, :a3, :b3, :d4, :b3],
                     [0.5, 1, 0.25, 0.25, 0.5, 1], amp: 0.32, release: 0.25
  sleep 0.5

  support_bar += 1
end
