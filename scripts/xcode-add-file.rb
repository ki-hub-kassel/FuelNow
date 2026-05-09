#!/usr/bin/env ruby
# scripts/xcode-add-file.rb
#
# Adds a Swift source file to the FuelNow Xcode project at a specific group path
# and registers it on one or more targets' Sources build phase. Idempotent: existing
# file references with matching path are reused; build-phase entries are not duplicated.
#
# Usage:
#   bundle exec ruby scripts/xcode-add-file.rb \
#     --file FuelNow/Path/To/File.swift \
#     --group "FuelNow/Path/To" \
#     --target FuelNow [--target FuelNowTests ...]
#
# Notes:
# - `--group` is the Xcode group hierarchy (display path), not necessarily the disk path.
# - `--file` is the disk path relative to the repo root.

require 'optparse'
require 'xcodeproj'

options = { targets: [] }
OptionParser.new do |opts|
  opts.on('--project PATH', 'Path to .xcodeproj') { |v| options[:project] = v }
  opts.on('--file PATH', 'Source file (repo-relative)') { |v| options[:file] = v }
  opts.on('--group PATH', 'Xcode group path (slash-separated)') { |v| options[:group] = v }
  opts.on('--target NAME', 'Target name (repeatable)') { |v| options[:targets] << v }
end.parse!

options[:project] ||= 'FuelNow.xcodeproj'

%i[file group].each do |k|
  abort("Missing --#{k}") if options[k].nil? || options[k].empty?
end
abort('Need at least one --target') if options[:targets].empty?

project = Xcodeproj::Project.open(options[:project])

# Resolve or create the group hierarchy.
def resolve_group(project, path)
  parts = path.split('/').reject(&:empty?)
  current = project.main_group
  parts.each do |segment|
    found = current.groups.find { |g| g.display_name == segment || g.name == segment || g.path == segment }
    current = found || current.new_group(segment, segment)
  end
  current
end

group = resolve_group(project, options[:group])

abs_path = File.expand_path(options[:file])
group_disk_path = File.expand_path(group.real_path.to_s)
relative_in_group = Pathname.new(abs_path).relative_path_from(Pathname.new(group_disk_path)).to_s

# Reuse existing file reference if already present.
file_ref = group.files.find do |f|
  f.real_path.to_s == abs_path
end

file_ref ||= group.new_reference(relative_in_group)

options[:targets].each do |target_name|
  target = project.targets.find { |t| t.name == target_name }
  abort("Target #{target_name} not found") unless target

  sources_phase = target.source_build_phase
  unless sources_phase.files_references.include?(file_ref)
    sources_phase.add_file_reference(file_ref, true)
  end
end

project.save
puts "Added #{options[:file]} to group '#{options[:group]}' on targets #{options[:targets].join(', ')}"
