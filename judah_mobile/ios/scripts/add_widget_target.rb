# Adds the JudahWidget WidgetKit extension to Runner.xcodeproj.
#
# Alex builds from Windows, so there is no Xcode to click the target together.
# CI runs this on the macOS runner before building; it is idempotent, so it is
# safe on every build, and once its result is committed it does nothing.
#
#   gem install xcodeproj   (already present wherever CocoaPods is)
#   ruby ios/scripts/add_widget_target.rb
require 'xcodeproj'

IOS_DIR = File.expand_path('..', __dir__)
project = Xcodeproj::Project.open(File.join(IOS_DIR, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target missing'

# The app itself needs the App Group to share data with the widget.
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

if project.targets.any? { |t| t.name == 'JudahWidget' }
  puts 'JudahWidget target already present'
  project.save
  exit 0
end

widget = project.new_target(:app_extension, 'JudahWidget', :ios, '17.0')
group = project.main_group.find_subpath('JudahWidget', true)
group.set_source_tree('<group>')
group.set_path('JudahWidget')
swift = group.new_reference('JudahWidget.swift')
group.new_reference('Info.plist')
group.new_reference('JudahWidget.entitlements')
widget.add_file_references([swift])
%w[WidgetKit SwiftUI].each do |fw|
  widget.add_system_framework(fw)
end

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.getjudah.app.JudahWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'JudahWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'JudahWidget/JudahWidget.entitlements'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks']
end

# Embed the extension in the app.
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.add_dependency(widget)

# Flutter's "Thin Binary" script must run after the embed phase, or Xcode
# reports a dependency cycle.
thin = runner.shell_script_build_phases.find { |p| p.name == 'Thin Binary' }
if thin
  runner.build_phases.delete(thin)
  runner.build_phases << thin
end

project.save
puts 'JudahWidget target added'
