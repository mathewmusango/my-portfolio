#!/usr/bin/env ruby
# frozen_string_literal: true

# UTF-8 + frontmatter parse for markdown files (Ruby psych — no installs).
# No args: scan docs/**. With args: check only those files (relative to the
# repo root). Exit 1 if any file has invalid frontmatter.

require "yaml"

root = File.expand_path("../../docs", __FILE__)
files = ARGV.empty? ? Dir.glob(File.join(root, "**", "*.md")).sort : ARGV
errors = 0

files.each do |path|
  content = File.read(path)
  if content.start_with?("---")
    parts = content.split(/^---\s*$/, 3)
    if parts.length >= 3 && !parts[1].strip.empty?
      begin
        YAML.safe_load(parts[1])
      rescue Psych::SyntaxError => e
        warn "ERROR #{path}: #{e.message.lines.first.strip}"
        errors += 1
        next
      end
    end
  end
  puts "ok: #{path}"
end

puts "#{errors} error(s)"
exit(errors.zero? ? 0 : 1)
