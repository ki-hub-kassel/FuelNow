#!/usr/bin/env ruby
# scripts/xcode-add-watch-target.rb
#
# Idempotent: legt das watchOS-Target `FuelNowWatch` im FuelNow-Xcode-Projekt an,
# verbindet es mit dem iOS-App-Target ueber eine "Embed Watch Content"-CopyFiles-
# Phase (`$(CONTENTS_FOLDER_PATH)/Watch`, dstSubfolderSpec = 16) und registriert
# die bestehenden Watch-Sources, die `Info.plist`, das App-Group-Entitlement und
# das `Assets.xcassets`. Der Watch-App-Bundle-Identifier ist eine Kindrolle des
# iOS-Bundles (`com.vibecoding.fuelnow.watchkitapp`) -- damit pairt watchOS die
# App automatisch mit dem iPhone, sobald `WKCompanionAppBundleIdentifier` in der
# `Info.plist` auf den iOS-Identifier zeigt.
#
# Verwendung:
#   bundle exec ruby scripts/xcode-add-watch-target.rb
#
# Wenn das Target bereits existiert, ist der Lauf ein No-Op (loggt jeden Schritt
# als "(already present)").

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../FuelNow.xcodeproj', __dir__)
WATCH_NAME = 'FuelNowWatch'
WATCH_GROUP_PATH = WATCH_NAME
WATCH_BUNDLE_ID = 'com.vibecoding.fuelnow.watchkitapp'
IOS_TARGET_NAME = 'FuelNow'
IOS_BUNDLE_ID = 'com.vibecoding.fuelnow'
DEV_TEAM = 'FNXU97S3QK'
WATCHOS_DEPLOYMENT_TARGET = '26.0'
SWIFT_VERSION = '6.0'
WATCH_SOURCES = %w[
  FuelNowWatchApp.swift
  FuelNowWatchRootView.swift
  FuelNowWatchSnapshotProvider.swift
].freeze
WATCH_RESOURCES = %w[Assets.xcassets].freeze

def log(msg)
  puts "[watch-target] #{msg}"
end

project = Xcodeproj::Project.open(PROJECT_PATH)

ios_target = project.targets.find { |t| t.name == IOS_TARGET_NAME }
abort "iOS-Target '#{IOS_TARGET_NAME}' not found in project" unless ios_target

watch_target = project.targets.find { |t| t.name == WATCH_NAME }

if watch_target
  log "Watch-Target '#{WATCH_NAME}' already exists -- skipping creation."
else
  log "Creating Watch-Target '#{WATCH_NAME}' (watchOS application, deployment #{WATCHOS_DEPLOYMENT_TARGET})."
  watch_target = project.new_target(
    :application,
    WATCH_NAME,
    :watchos,
    WATCHOS_DEPLOYMENT_TARGET,
    project.products_group,
    :swift
  )
end

# Resolve / create the FuelNowWatch group as a sibling of FuelNow / FuelNowWidgets
watch_group = project.main_group[WATCH_GROUP_PATH]
unless watch_group
  log "Creating group '#{WATCH_GROUP_PATH}'."
  watch_group = project.main_group.new_group(WATCH_NAME, WATCH_GROUP_PATH)
end

def find_or_create_file_ref(group, relative_path)
  existing = group.files.find { |f| f.path == relative_path || f.display_name == relative_path }
  return existing if existing

  group.new_reference(relative_path)
end

# Add file references for sources, Info.plist, entitlements, and Assets.xcassets to the group.
source_refs = WATCH_SOURCES.map do |name|
  ref = find_or_create_file_ref(watch_group, name)
  log "  source: #{name} (#{ref.uuid})"
  ref
end

info_plist_ref = find_or_create_file_ref(watch_group, 'Info.plist')
entitlements_ref = find_or_create_file_ref(watch_group, 'FuelNowWatch.entitlements')
resource_refs = WATCH_RESOURCES.map do |name|
  ref = find_or_create_file_ref(watch_group, name)
  log "  resource: #{name} (#{ref.uuid})"
  ref
end

# Sources build phase
sources_phase = watch_target.source_build_phase
source_refs.each do |ref|
  if sources_phase.files_references.include?(ref)
    log "  source already linked: #{ref.path}"
  else
    sources_phase.add_file_reference(ref, true)
    log "  linked source: #{ref.path}"
  end
end

# Resources build phase (Assets.xcassets)
resources_phase = watch_target.resources_build_phase
resource_refs.each do |ref|
  if resources_phase.files_references.include?(ref)
    log "  resource already linked: #{ref.path}"
  else
    resources_phase.add_file_reference(ref, true)
    log "  linked resource: #{ref.path}"
  end
end

# Build settings (Debug + Release) -- mirror project conventions where it makes sense.
common_settings = {
  'PRODUCT_BUNDLE_IDENTIFIER' => WATCH_BUNDLE_ID,
  'PRODUCT_NAME' => WATCH_NAME,
  'INFOPLIST_FILE' => "#{WATCH_NAME}/Info.plist",
  'GENERATE_INFOPLIST_FILE' => 'NO',
  'CODE_SIGN_ENTITLEMENTS' => "#{WATCH_NAME}/FuelNowWatch.entitlements",
  'CODE_SIGN_STYLE' => 'Automatic',
  'DEVELOPMENT_TEAM' => DEV_TEAM,
  'SDKROOT' => 'watchos',
  'SUPPORTED_PLATFORMS' => 'watchsimulator watchos',
  'TARGETED_DEVICE_FAMILY' => '4',
  'WATCHOS_DEPLOYMENT_TARGET' => WATCHOS_DEPLOYMENT_TARGET,
  'SWIFT_VERSION' => SWIFT_VERSION,
  'SWIFT_STRICT_CONCURRENCY' => 'complete',
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'CURRENT_PROJECT_VERSION' => '1',
  'MARKETING_VERSION' => '1.0',
  'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks'],
  'ENABLE_PREVIEWS' => 'YES'
}

watch_target.build_configurations.each do |config|
  config.build_settings.merge!(common_settings)
  if config.name == 'Debug'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG $(inherited)'
  else
    config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
    config.build_settings['VALIDATE_PRODUCT'] = 'YES'
  end
  log "  configured build settings for #{config.name}"
end

# --- Embed Watch Content into the iOS app ----------------------------------
embed_phase_name = 'Embed Watch Content'
embed_phase = ios_target.copy_files_build_phases.find { |p| p.name == embed_phase_name }
unless embed_phase
  log "Adding 'Embed Watch Content' build phase to '#{IOS_TARGET_NAME}'."
  embed_phase = ios_target.new_copy_files_build_phase(embed_phase_name)
  embed_phase.dst_subfolder_spec = '16' # ProductsDirectory-relative; combined with dst_path = Watch
  embed_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
  embed_phase.symbol_dst_subfolder_spec = :products_directory if embed_phase.respond_to?(:symbol_dst_subfolder_spec)
end

watch_product_ref = watch_target.product_reference

already_embedded = embed_phase.files_references.include?(watch_product_ref)
if already_embedded
  log "  watch app already embedded into #{IOS_TARGET_NAME}."
else
  build_file = embed_phase.add_file_reference(watch_product_ref, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  log "  embedded #{watch_product_ref.path} into #{IOS_TARGET_NAME}."
end

# Target dependency: building FuelNow first builds FuelNowWatch.
unless ios_target.dependencies.any? { |d| d.target == watch_target }
  ios_target.add_dependency(watch_target)
  log "Added target dependency #{IOS_TARGET_NAME} -> #{WATCH_NAME}."
else
  log "Target dependency already present."
end

project.save
log "Saved project to #{PROJECT_PATH}."
