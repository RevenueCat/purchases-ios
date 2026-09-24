# Layout regression for the RevenueCatUI SwiftPM schemes.
# Package-level shared schemes are imported by SwiftPM consumers, so these
# development schemes live in RevenueCatUI-SPM.xcworkspace instead.
# Run with: ruby fastlane/spm_scheme_layout_test.rb

require 'minitest/autorun'
require 'rexml/document'

class SPMSchemeLayoutTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  WORKSPACE = 'RevenueCatUI-SPM.xcworkspace'
  PACKAGE_REFERENCE = 'group:.'
  PACKAGE_CONTAINER = 'container:.'
  SCHEME_NAMES = %w[RevenueCatUI RevenueCatUI-Stripped RevenueCatUITests].freeze

  REVENUECATUI_TEST_PLANS = %w[
    Tests/RevenueCatUITests/TestPlans/RevenueCatUI.xctestplan
    Tests/RevenueCatUITests/TestPlans/CI-Snapshots.xctestplan
    Tests/RevenueCatUITests/TestPlans/CI-RevenueCatUI.xctestplan
    Tests/RevenueCatUITests/TestPlans/RevenueCatUI-UnitTests.xctestplan
    Tests/RevenueCatUITests/TestPlans/Paywall-Screenshots.xctestplan
    Tests/RevenueCatUITests/TestPlans/CI-V1-Snapshots.xctestplan
  ].freeze

  BUILD_CONFIGURATIONS = {
    'RevenueCatUI' => {
      'TestAction' => 'Debug',
      'LaunchAction' => 'Debug',
      'ProfileAction' => 'Release',
      'AnalyzeAction' => 'Debug',
      'ArchiveAction' => 'Release'
    },
    'RevenueCatUI-Stripped' => {
      'TestAction' => 'Release',
      'LaunchAction' => 'Release',
      'ProfileAction' => 'Release',
      'AnalyzeAction' => 'Release',
      'ArchiveAction' => 'Release'
    },
    'RevenueCatUITests' => {
      'TestAction' => 'Debug',
      'LaunchAction' => 'Debug',
      'ProfileAction' => 'Release',
      'AnalyzeAction' => 'Debug',
      'ArchiveAction' => 'Release'
    }
  }.freeze

  def test_package_level_custom_schemes_are_absent
    SCHEME_NAMES.each do |name|
      path = File.join(ROOT, '.swiftpm/xcode/xcshareddata/xcschemes', "#{name}.xcscheme")
      refute File.exist?(path), "#{path} is a shared package scheme and would be imported by SwiftPM consumers"
    end
  end

  def test_gitignore_ignores_package_level_generated_schemes
    gitignore = File.read(File.join(ROOT, '.gitignore'))
    assert_includes gitignore, ".swiftpm/xcode/xcshareddata/xcschemes/*.xcscheme"
    refute_includes gitignore, "RC and RCUI need to be tested through the package"
  end

  def test_workspace_references_the_root_package
    document = parse("#{WORKSPACE}/contents.xcworkspacedata")
    assert_equal 'Workspace', document.root.name

    locations = REXML::XPath.match(document, '//FileRef').map { |node| node.attributes['location'] }
    assert_equal [PACKAGE_REFERENCE], locations
  end

  def test_relocated_schemes_parse_and_buildables_resolve_to_the_package
    SCHEME_NAMES.each do |name|
      document = parse(scheme_path(name))
      assert_equal 'Scheme', document.root.name

      references = REXML::XPath.match(document, '//BuildableReference')
      refute_empty references, "#{name} has no package buildable references"

      references.each do |reference|
        blueprint = reference.attributes['BlueprintName']
        assert_equal PACKAGE_CONTAINER, reference.attributes['ReferencedContainer'],
                     "#{name} buildable #{blueprint} must resolve to the root package"
        assert_equal blueprint, reference.attributes['BlueprintIdentifier'],
                     "#{name} buildable #{blueprint} must keep its package target identifier"
        assert_equal blueprint, reference.attributes['BuildableName']
      end

      BUILD_CONFIGURATIONS.fetch(name).each do |action, configuration|
        node = REXML::XPath.first(document, "//#{action}")
        refute_nil node, "#{name} is missing #{action}"
        assert_equal configuration, node.attributes['buildConfiguration'], "#{name} #{action}"
      end
    end
  end

  def test_every_declared_test_plan_path_exists
    SCHEME_NAMES.each do |name|
      document = parse(scheme_path(name))
      REXML::XPath.match(document, '//TestPlanReference').each do |plan|
        path = package_relative_test_plan_path(plan.attributes['reference'])
        assert File.file?(File.join(ROOT, path)), "#{name} test plan does not exist: #{path}"
      end
    end
  end

  def test_revenuecatui_scheme_retains_its_test_plans
    document = parse(scheme_path('RevenueCatUI'))
    plans = REXML::XPath.match(document, '//TestPlanReference')
    paths = plans.map { |plan| package_relative_test_plan_path(plan.attributes['reference']) }

    assert_equal REVENUECATUI_TEST_PLANS, paths

    default_plans = plans.select { |plan| plan.attributes['default'] == 'YES' }
    assert_equal 1, default_plans.length
    assert_equal REVENUECATUI_TEST_PLANS.first,
                 package_relative_test_plan_path(default_plans.first.attributes['reference'])

    testables = REXML::XPath.match(document, '//TestAction//BuildableReference')
    assert_equal ['RevenueCatUITests'], testables.map { |node| node.attributes['BlueprintName'] }
  end

  def test_stripped_release_testing_selects_purchases_ui_service_integration_tests
    document = parse(scheme_path('RevenueCatUI-Stripped'))
    test_action = REXML::XPath.first(document, '//TestAction')
    assert_equal 'Release', test_action.attributes['buildConfiguration']
    assert_empty REXML::XPath.match(document, '//TestPlanReference')

    testables = REXML::XPath.match(document, '//TestAction//TestableReference')
    assert_equal 1, testables.length
    assert_equal 'NO', testables.first.attributes['skipped']

    reference = REXML::XPath.first(testables.first, './/BuildableReference')
    assert_equal 'PurchasesUIServiceIntegrationTests', reference.attributes['BlueprintName']
    assert_equal 'PurchasesUIServiceIntegrationTests', reference.attributes['BlueprintIdentifier']
    assert_equal PACKAGE_CONTAINER, reference.attributes['ReferencedContainer']

    testing_entry = REXML::XPath.match(document, '//BuildActionEntry').find do |entry|
      REXML::XPath.first(entry, './/BuildableReference').attributes['BlueprintName'] ==
        'PurchasesUIServiceIntegrationTests'
    end
    refute_nil testing_entry, 'stripped scheme must build PurchasesUIServiceIntegrationTests for testing'
    assert_equal 'YES', testing_entry.attributes['buildForTesting']
    assert_equal 'NO', testing_entry.attributes['buildForRunning']
  end

  def test_revenuecatui_fastlane_lanes_use_the_dedicated_workspace
    fastfile = File.read(File.join(ROOT, 'fastlane/Fastfile'))
    refute_includes fastfile, "workspace: '.'"

    {
      'record_and_upload_v1_snapshots' => 'RevenueCatUI',
      'test_revenuecatui' => 'RevenueCatUI',
      'test_purchases_ui_service_stripped' => 'RevenueCatUI-Stripped'
    }.each do |lane_name, scheme|
      body = lane_source(fastfile, lane_name)
      assert_includes body, "workspace: 'RevenueCatUI-SPM.xcworkspace'", lane_name
      assert_includes body, "scheme: '#{scheme}'", lane_name
    end

    stripped = lane_source(fastfile, 'test_purchases_ui_service_stripped')
    assert_includes stripped, "configuration: 'Release'"
    assert_includes stripped, 'DEAD_CODE_STRIPPING=YES STRIP_SWIFT_SYMBOLS=YES ONLY_ACTIVE_ARCH=YES'

    snapshots = lane_source(fastfile, 'record_and_upload_v1_snapshots')
    assert_includes snapshots, 'xcargs: "-testPlan CI-V1-Snapshots"'

    ui_tests = lane_source(fastfile, 'test_revenuecatui')
    assert_includes ui_tests, '-collect-test-diagnostics'
    assert_includes ui_tests, 'CI-RevenueCatUI'
    assert_includes ui_tests, 'CI-Snapshots'
  end

  private

  def scheme_path(name)
    "#{WORKSPACE}/xcshareddata/xcschemes/#{name}.xcscheme"
  end

  def parse(relative_path)
    REXML::Document.new(File.read(File.join(ROOT, relative_path)))
  end

  # Test-plan references stay relative to the package root. `container:` is the
  # scheme location prefix; the remainder is the path checked on disk.
  def package_relative_test_plan_path(reference)
    assert_match(/\Acontainer:/, reference)
    path = reference.delete_prefix('container:')
    path = path.delete_prefix('./')
    refute path.start_with?('/'), "#{reference} is not package-root relative"
    refute path.split('/').include?('..'), "#{reference} escapes the package root"
    path
  end

  def lane_source(fastfile, lane_name)
    match = fastfile.match(/^[ ]+lane :#{Regexp.escape(lane_name)} do\b.*$/)
    refute_nil match, "missing lane #{lane_name}"

    rest = fastfile[match.end(0)..]
    next_lane = rest.match(/^[ ]+(?:private_)?lane :/)
    finish = next_lane ? match.end(0) + next_lane.begin(0) : fastfile.length
    fastfile[match.begin(0)...finish]
  end
end
