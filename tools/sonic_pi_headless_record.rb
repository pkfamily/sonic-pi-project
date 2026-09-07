#!/usr/bin/env ruby

# Sonic Pi v5-compatible headless recorder.
# The bundled harness uses UDP for the SuperSonic engine, while v5 exposes the
# engine command port over framed TCP. This keeps the official boot sequence
# and changes only that transport.

require "fileutils"

sonic_pi_app_root = ENV.fetch(
  "SONIC_PI_APP_ROOT",
  "/Applications/Sonic Pi.app/Contents/Resources/app/server/ruby"
)
require_relative File.join(sonic_pi_app_root, "bin/headless_boot")

USAGE = "Usage: sonic_pi_headless_record.rb -o OUT.wav -d SECONDS -f FILE.rb"

args = ARGV.dup
out_path = nil
duration = nil
script_path = nil

value = lambda do |flag|
  abort "#{flag} needs a value\n#{USAGE}" if args.empty?
  args.shift
end

until args.empty?
  case (flag = args.shift)
  when "-o" then out_path = value.call(flag)
  when "-d" then duration = value.call(flag).to_f
  when "-f" then script_path = value.call(flag)
  when "-h", "--help" then puts USAGE; exit 0
  else abort "Unknown argument: #{flag}\n#{USAGE}"
  end
end

abort USAGE unless out_path && duration && duration > 0 && script_path
abort "File not found: #{script_path}" unless File.file?(script_path)

out_path = File.expand_path(out_path)
FileUtils.mkdir_p(File.dirname(out_path))

boot = SonicPi::HeadlessBoot.new
boot.boot!

engine_port = boot.engine_client.instance_variable_get(:@port)
boot.instance_variable_set(
  :@engine_client,
  SonicPi::OSC::TcpOscClient.new("localhost", engine_port)
)

boot.say "READY — recording #{duration}s to #{out_path}"
boot.engine_client.send(nil, nil, "/supersonic/record/start", out_path, "wav", 24)
boot.run(File.read(script_path))

sleep duration
boot.engine_client.send(nil, nil, "/supersonic/record/stop")
sleep 2
boot.stop_all
sleep 1

if File.file?(out_path) && File.size(out_path) > 0
  boot.say "WROTE #{out_path} (#{File.size(out_path)} bytes)"
else
  boot.say "FAILED — no output written"
  exit 1
end
