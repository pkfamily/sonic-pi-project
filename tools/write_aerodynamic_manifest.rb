#!/usr/bin/env ruby

require "digest"
require "json"
require "shellwords"
require "time"

root = File.expand_path("..", __dir__)
output_dir = File.join(root, "renders/aerodynamic_v10")
source = File.join(root, "tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb")
renderer = File.join(root, "tools/render_aerodynamic_stems.rb")
files = Dir[File.join(output_dir, "aerodynamic_v10_*.wav")].sort
abort "No rendered WAVs found in #{output_dir}" if files.empty?

relative = lambda { |path| path.delete_prefix("#{root}/") }
manifest = {
  "generated_at_utc" => Time.now.utc.iso8601,
  "git_revision" => begin
    stdout = `git -C #{Shellwords.escape(root)} rev-parse HEAD 2>/dev/null`.strip
    stdout.empty? ? nil : stdout
  end,
  "source" => {"path" => relative.call(source), "sha256" => Digest::SHA256.file(source).hexdigest},
  "renderer" => {"path" => relative.call(renderer), "sha256" => Digest::SHA256.file(renderer).hexdigest},
  "sonic_pi_tool_fork" => {
    "repository" => "https://github.com/pkfamily/sonic-pi-tool",
    "commit" => "b955369294b7669b2706b26d388ec2c2a9d0d3a2"
  },
  "files" => files.to_h do |path|
    [File.basename(path, ".wav").sub("aerodynamic_v10_", ""), {
      "path" => relative.call(path),
      "bytes" => File.size(path),
      "sha256" => Digest::SHA256.file(path).hexdigest
    }]
  end
}

File.write(File.join(output_dir, "manifest.json"), JSON.pretty_generate(manifest) + "\n")
puts "Wrote #{File.join(output_dir, "manifest.json")}"
