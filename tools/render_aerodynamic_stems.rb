#!/usr/bin/env ruby

# Render aligned Sonic Pi stems from the V10 stem-aware arrangement.
# Uses Sonic Pi's bundled headless-record harness so current daemon tokens and
# SuperSonic recording are handled by Sonic Pi itself.

require "fileutils"
require "digest"
require "json"
require "open3"
require "tmpdir"
require "time"

ROOT = File.expand_path("..", __dir__)
SOURCE = File.join(ROOT, "tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb")
OUTPUT_DIR = File.join(ROOT, "renders/aerodynamic_v10")
SONG_SECONDS = 210
PROFILES = %w[full drums bass lead melody harmony fx]

requested = ARGV.empty? ? PROFILES : ARGV
unknown = requested - PROFILES
abort "Unknown profile(s): #{unknown.join(", ")}" unless unknown.empty?
abort "Missing source: #{SOURCE}" unless File.file?(SOURCE)

headless_record = ENV.fetch(
  "SONIC_PI_HEADLESS_RECORD",
  File.join(ROOT, "tools/sonic_pi_headless_record.rb")
)
abort "Cannot find Sonic Pi headless recorder: #{headless_record}" unless File.file?(headless_record)

source_code = File.read(SOURCE)
FileUtils.mkdir_p(OUTPUT_DIR)

def run_command(*command)
  stdout, stderr, status = Open3.capture3(*command)
  warn stdout unless stdout.empty?
  warn stderr unless stderr.empty?
  abort "Command failed (#{status.exitstatus}): #{command.join(" ")}" unless status.success?
end

requested.each do |profile|
  output_path = File.join(OUTPUT_DIR, "aerodynamic_v10_#{profile}.wav")
  temp_path = File.join(Dir.tmpdir, "aerodynamic_v10_#{Process.pid}_#{profile}.rb")
  profile_code = source_code.sub(
    "set :render_profile, :full",
    "set :render_profile, :#{profile}"
  )
  # Keep the finite program alive while headless-record sends its stop command.
  profile_code = "#{profile_code}\n\nsleep 8\n"
  File.write(temp_path, profile_code)

  puts "Rendering #{profile} -> #{output_path}"
  begin
    run_command("ruby", headless_record, "-o", output_path,
      "-d", SONG_SECONDS.to_s, "-f", temp_path)
  ensure
    File.delete(temp_path) if File.file?(temp_path)
  end

  abort "No WAV produced: #{output_path}" unless File.file?(output_path)
end

puts "Finished #{requested.length} render(s) in #{OUTPUT_DIR}"

git_revision = begin
  stdout, _stderr, status = Open3.capture3("git", "rev-parse", "HEAD", chdir: ROOT)
  status.success? ? stdout.strip : nil
end

manifest = {
  "generated_at_utc" => Time.now.utc.iso8601,
  "git_revision" => git_revision,
  "source" => {
    "path" => SOURCE.delete_prefix("#{ROOT}/"),
    "sha256" => Digest::SHA256.file(SOURCE).hexdigest
  },
  "renderer" => {
    "path" => __FILE__.delete_prefix("#{ROOT}/"),
    "sha256" => Digest::SHA256.file(__FILE__).hexdigest
  },
  "sonic_pi_headless_record" => headless_record,
  "sonic_pi_tool_fork" => {
    "repository" => "https://github.com/pkfamily/sonic-pi-tool",
    "commit" => "b955369294b7669b2706b26d388ec2c2a9d0d3a2",
    "role" => "optional CLI/control tool; the v5 stem renderer uses the TCP adapter"
  },
  "profiles" => requested,
  "song_seconds" => SONG_SECONDS,
  "files" => requested.to_h do |profile|
    path = File.join(OUTPUT_DIR, "aerodynamic_v10_#{profile}.wav")
    [profile, {
      "path" => path.delete_prefix("#{ROOT}/"),
      "bytes" => File.size(path),
      "sha256" => Digest::SHA256.file(path).hexdigest
    }]
  end
}
manifest_path = File.join(OUTPUT_DIR, "manifest.json")
File.write(manifest_path, JSON.pretty_generate(manifest) + "\n")
puts "Wrote #{manifest_path}"
