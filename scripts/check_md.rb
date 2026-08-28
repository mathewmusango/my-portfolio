#!/usr/bin/env ruby
# frozen_string_literal: true

# UTF-8 + frontmatter parse for markdown files (Ruby psych — no installs).
# No args: scan every *.md in the repo (excluding site/ + .git). With args:
# check only those files (relative to the repo root). Exit 1 if any file has
# invalid frontmatter.

require "yaml"

root = File.expand_path("../..", __FILE__)
files =
  if ARGV.empty?
    Dir.glob(File.join(root, "**", "*.md")).sort.reject { |p|
      p.include?("/site/") || p.include?("/.git/")
    }
  else
    ARGV
  end
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
