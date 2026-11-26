require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'yaml'
require 'rbconfig'
require 'fastlane'
require_relative 'workflow_trace'

Fastlane::Actions.load_default_actions

class WorkflowTraceLaneTest < Minitest::Test
  FASTFILE = Fastlane::FastFile.new(File.expand_path('Fastfile', __dir__))

  def setup
    @directory = Dir.mktmpdir('workflow trace ')
    @commands = []
    commands = @commands
    FASTFILE.define_singleton_method(:xcodebuild) { |options| commands << [:build, options] }
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def run_lane(options, result: 0)
    commands = @commands
    factory = lambda do |**arguments|
      commands << [:run, arguments]
      Object.new.tap { |runner| runner.define_singleton_method(:run) { result } }
    end
    WorkflowTrace.stub(:new, factory) do
      Dir.chdir(__dir__) { FASTFILE.runner.lanes.fetch(:ios).fetch(:workflow_trace).call(options) }
    end
  end

  def test_preserves_build_settings_and_paths_with_spaces
    output = File.join(@directory, 'new capture')
    File.write(File.join(@directory, 'summary.json'), '{}')
    run_lane({device: 'simulator-id', output: output, baseline: @directory, iterations: '8'})
    assert_equal [:build, :run], @commands.map(&:first)
    build = @commands.first.last
    assert_equal File.expand_path('../RevenueCat-Tuist.xcworkspace', __dir__), build[:workspace]
    assert_equal 'Release', build[:configuration]
    assert_equal '-O', build[:build_settings]['SWIFT_OPTIMIZATION_LEVEL']
    assert_equal '$(inherited) DEBUG', build[:build_settings]['SWIFT_ACTIVE_COMPILATION_CONDITIONS']
    assert_equal 'NO', build[:build_settings]['CODE_SIGNING_ALLOWED']
    arguments = @commands.last.last
    assert_equal @directory, arguments[:baseline]
    assert_equal '8', arguments[:iterations]
    assert_equal output, arguments[:output]
    assert File.absolute_path(arguments[:app]) == arguments[:app]
  end

  def test_default_device_requires_one_matching_simulator
    runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-27-0'
    device = {'name' => 'iPhone 17', 'udid' => 'target'}
    devices = {runtime => [device, {'name' => 'iPhone 17 Pro', 'udid' => 'pro'}],
               'com.apple.CoreSimulator.SimRuntime.iOS-26-0' => [device.merge('udid' => 'older')]}
    FASTFILE.stub(:sh, ->(*) { JSON.generate('devices' => devices) }) do
      options = {output: File.join(@directory, 'capture')}
      run_lane(options)
      assert_equal 'platform=iOS Simulator,id=target', @commands.first.last[:destination]
      assert_equal 'target', @commands.last.last[:device]
      [[], [device, device.merge('udid' => 'second')]].each do |matches|
        devices[runtime] = matches
        error = assert_raises(FastlaneCore::Interface::FastlaneError) { run_lane(options) }
        assert_includes error.message, 'Expected one iPhone 17'
      end
    end
  end

  def test_record_mode_can_seed_a_missing_baseline_but_comparison_requires_it
    options = {device: 'simulator-id', output: File.join(@directory, 'capture'), baseline: @directory}
    run_lane(options.merge(record_baseline: true))
    assert_nil @commands.last.last[:baseline]
    @commands.clear
    error = assert_raises(FastlaneCore::Interface::FastlaneError) { run_lane(options.merge(record_baseline: false)) }
    assert_includes error.message, 'summary.json'
    assert_empty @commands
  end

  def test_existing_results_stop_before_build
    assert_raises(FastlaneCore::Interface::FastlaneError) do
      run_lane({device: 'simulator-id', output: @directory})
    end
    assert_empty @commands
  end

  def test_regression_and_inconclusive_results_fail_the_lane
    [1, 2].each do |code|
      assert_raises(FastlaneCore::Interface::FastlaneError) do
        run_lane({device: 'simulator-id', output: File.join(@directory, 'new')}, result: code)
      end
    end
  end
end

class WorkflowTraceTest < Minitest::Test
  def test_danger_warns_when_the_benchmark_runner_changes
    require_relative '../.circleci/workflow_benchmark_runner'
    config = <<~YAML
      executors:
        mac:
          parameters:
            xcode_version: {type: string, default: "16.4"}
          macos: {xcode: << parameters.xcode_version >>}
          resource_class: &hardware m4pro.medium
          environment: {RC_CI_RESOURCE_CLASS: *hardware}
      jobs:
        workflow-instruments:
          executor: {name: mac, xcode_version: "27.0.0"}
        unrelated:
          executor: {name: mac, xcode_version: "26.0.0"}
    YAML
    hardware = WorkflowBenchmarkRunner.warning(config, config.sub('m4pro.medium', 'm4pro.large'))
    assert_includes hardware, 'm4pro.medium'
    assert_includes hardware, 'm4pro.large'
    assert_includes hardware, 'on `main` with `requested_jobs=record-workflow-performance-baseline`'
    image = WorkflowBenchmarkRunner.warning(config, config.sub('27.0.0', '27.1.0'))
    assert_includes image, '27.1.0'
    assert_nil WorkflowBenchmarkRunner.warning(config, config.sub('26.0.0', '26.1.0'))
    assert_nil WorkflowBenchmarkRunner.warning(config, config.sub('16.4', '16.5'))
    assert_nil WorkflowBenchmarkRunner.warning('jobs: {}', config)
  end

  def setup
    @directory = Dir.mktmpdir('workflow runner ')
    @runner = WorkflowTrace.new(device: 'device', output: File.join(@directory, 'result'), app: File.join(@directory, 'app'))
    @manifest = {'status' => 'complete', 'workload' => {'blob_ref' => 'revision-a', 'ui_config_sha256' => 'abc'},
                 'environment' => {'xcode' => '26.0', 'model' => 'iPhone18,1'}, 'commit' => 'old',
                 'executable_sha256' => 'app', 'sdk_diff_sha256' => 'sdk'}
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_compatibility_allows_sdk_changes_but_reports_content_and_environment_changes
    current = Marshal.load(Marshal.dump(@manifest))
    current['commit'] = 'new'
    WorkflowTrace.require_compatible(current, @manifest)
    [%w[workload blob_ref], %w[workload ui_config_sha256], %w[environment model], %w[environment xcode]].each do |section, key|
      changed = Marshal.load(Marshal.dump(current))
      changed[section][key] = 'changed'
      error = assert_raises(RuntimeError) { WorkflowTrace.require_compatible(changed, @manifest) }
      assert_includes error.message, "#{section}.#{key}"
      assert_includes error.message, @manifest[section][key]
      assert_includes error.message, 'changed'
    end
    @manifest['status'] = 'failed'
    assert_raises(RuntimeError) { WorkflowTrace.require_compatible(current, @manifest) }
  end

  def test_batch_writes_summary_and_names_incompatible_iteration
    Dir.mkdir(File.join(@directory, 'app.dSYM'))
    File.write(File.join(@directory, 'app.dSYM', 'symbols'), 'fixture')
    @runner.stub(:record, [@manifest, {'present' => 100, 'next' => 200}]) do
      assert_equal 0, @runner.run
    end
    assert_equal 'fixture', File.read(File.join(@directory, 'result/symbols/app.dSYM/symbols'))
    result = JSON.parse(File.read(File.join(@directory, 'result/summary.json')))
    assert_equal 6, result['samples'].length
    assert_equal 300, result['statistics']['Total journey']['median_ms']
    assert_includes File.read(File.join(@directory, 'result/comparison.txt')), 'No performance comparison'
    FileUtils.remove_entry(File.join(@directory, 'result'))
    changed = Marshal.load(Marshal.dump(@manifest))
    changed['environment']['xcode'] = '27.0'
    captures = [[@manifest, {'present' => 100}], [changed, {'present' => 100}]]
    @runner.stub(:record, ->(_) { captures.shift }) do
      error = assert_raises(RuntimeError) { @runner.run }
      assert_includes error.message, 'iteration-01'
      assert_includes error.message, 'environment.xcode'
      refute_includes error.message, 'baseline'
    end
  end

  def test_main_baseline_writers_share_one_serial_group
    config = YAML.safe_load_file(File.join(WorkflowTrace::ROOT, '.circleci/default_config.yml'), aliases: true)
    jobs = config.fetch('workflows').values.flat_map { |workflow| workflow.fetch('jobs', []) }
    automatic = jobs.grep(Hash).find { |job| job.key?('workflow-instruments') }.fetch('workflow-instruments')
    group = automatic.fetch('serial-group')
    refute_empty group

    record_job = 'record-workflow-performance-baseline'
    env = {'REQUESTED_JOBS' => "workflow-instruments #{record_job}", 'CIRCLE_BRANCH' => 'main'}
    output = File.join(@directory, 'requested-jobs.yml')
    message, status = Open3.capture2e(env, 'node', '.circleci/generate-requested-jobs-config.js', output, chdir: WorkflowTrace::ROOT)
    assert status.success?, message
    requested = YAML.safe_load_file(output, aliases: true)
    compare, record = requested.fetch('workflows').fetch('on-demand-jobs').fetch('jobs').map { |job| job.fetch('workflow-instruments') }
    assert_equal group, compare.fetch('serial-group')
    assert_equal group, record.fetch('serial-group')
    assert_equal true, record.fetch('record_baseline')
    assert_equal record_job, record.fetch('name')
  end

  def test_older_run_cannot_replace_newer_baseline
    script = File.expand_path('../.circleci/save-workflow-baseline.sh', __dir__)
    Dir.chdir(@directory) do
      assert system('git', 'init', '--quiet')
      commits = %w[first second].map do |name|
        assert system('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                      '-c', 'commit.gpgsign=false', 'commit', '--quiet', '--allow-empty', '-m', name)
        `git rev-parse HEAD`.strip
      end
      publish = lambda do |commit|
        File.write('candidate.json', JSON.generate('commit' => commit))
        Open3.capture2e('bash', script, 'candidate.json', 'cache')
      end
      commits.each do |commit|
        message, status = publish.call(commit)
        assert status.success?, message
        assert_equal commit, JSON.parse(File.read('cache/summary.json')).fetch('commit')
      end
      message, status = publish.call(commits.first)
      refute status.success?, 'Older run replaced the newer baseline'
      assert_includes message, 'ancestor'
      assert_equal commits.last, JSON.parse(File.read('cache/summary.json')).fetch('commit')
    end
  end

  def test_saved_maestro_version_excludes_analytics_notice
    notice = "Anonymous analytics enabled. To opt out, set MAESTRO_CLI_NO_ANALYTICS environment variable to any value before running Maestro.\n\n"
    [[notice + '2.5.0', '2.5.0'], ['2.5.0', '2.5.0'], ['2.6.0', '2.6.0']].each_with_index do |(text, expected), index|
      environment = capture_environment("maestro-#{index}", ['maestro', '--version'] => text)
      assert_equal expected, environment.fetch('maestro')
    end
  end

  def test_comparison_rejects_runner_changes_with_the_same_virtual_mac_model
    previous_class = ENV['RC_CI_RESOURCE_CLASS']
    ENV['RC_CI_RESOURCE_CLASS'] = 'm4pro.medium'
    baseline = @manifest.merge('environment' => capture_environment('baseline'))
    cases = [
      ['cpu_model', {['sysctl', '-in', 'machdep.cpu.brand_string'] => 'Apple M5 Pro'}],
      ['logical_cpus', {['sysctl', '-n', 'hw.logicalcpu'] => '12'}],
      ['ci_resource_class', {}]
    ]
    cases.each do |field, commands|
      ENV['RC_CI_RESOURCE_CLASS'] = 'm4pro.large' if field == 'ci_resource_class'
      current = @manifest.merge('environment' => capture_environment(field, commands))
      error = assert_raises(RuntimeError) { WorkflowTrace.require_compatible(current, baseline) }
      assert_includes error.message, "environment.#{field}"
    end
  ensure
    ENV['RC_CI_RESOURCE_CLASS'] = previous_class
  end

  def test_action_windows_end_when_maestro_confirms_the_destination_is_visible
    commands = [['Present Paywall', 100100], ['Continue 1/3', 101000], ['Continue 2/3', 103000]].flat_map do |label, timestamp|
      [{'command' => {'tapOnElement' => {'selector' => {'textRegex' => label}}},
        'metadata' => {'status' => 'COMPLETED', 'timestamp' => timestamp, 'duration' => 500}},
       {'command' => {'assertConditionCommand' => {'condition' => {'visible' => {'textRegex' => 'Next screen'}}}},
        'metadata' => {'status' => 'COMPLETED', 'timestamp' => timestamp + 500, 'duration' => 300}}]
    end
    assert_equal [
      {'action' => 'Present Paywall', 'start_seconds' => 0.1, 'end_seconds' => 0.9},
      {'action' => 'Continue 1/3', 'start_seconds' => 1, 'end_seconds' => 1.8},
      {'action' => 'Continue 2/3', 'start_seconds' => 3, 'end_seconds' => 3.8}
    ], WorkflowTrace.action_windows(commands.reverse, 100)
    assert_raises(RuntimeError) { WorkflowTrace.action_windows(commands.drop(1), 100) }
    assert_raises(RuntimeError) { WorkflowTrace.action_windows(commands[0...-1], 100) }
    commands.last['metadata']['status'] = 'FAILED'
    assert_raises(RuntimeError) { WorkflowTrace.action_windows(commands, 100) }
    commands.last['metadata']['status'] = 'COMPLETED'
    commands.first['metadata']['status'] = 'FAILED'
    assert_raises(RuntimeError) { WorkflowTrace.action_windows(commands, 100) }
  end

  def test_first_screen_context_must_be_built_entirely_during_the_presentation_window
    path = File.join(@directory, 'os-signpost.xml')
    File.write(path, <<~XML)
      <node>
        <row><event-time>2100000000</event-time><event-type>Begin</event-type>
          <signpost-name id="1">Build workflow context</signpost-name><subsystem id="2">com.revenuecat.workflow-profile</subsystem></row>
        <row><event-time>2300000000</event-time><event-type>End</event-type>
          <signpost-name ref="1"/><subsystem ref="2"/></row>
      </node>
    XML
    WorkflowTrace.verify_context_timing(path, {'start_seconds' => 2.0, 'end_seconds' => 2.5})
    [[2.2, 2.5], [2.0, 2.2]].each do |start_time, end_time|
      error = assert_raises(RuntimeError) do
        WorkflowTrace.verify_context_timing(path, {'start_seconds' => start_time, 'end_seconds' => end_time})
      end
      assert_includes error.message, 'outside the presentation window'
    end
    File.write(path, '<node/>')
    error = assert_raises(RuntimeError) { WorkflowTrace.verify_context_timing(path, {}) }
    assert_includes error.message, 'Expected one first-screen context build'
  end

  def test_distinguishes_a_duplicate_signpost_table_from_a_second_context_build
    path = File.join(@directory, 'os-signpost.xml')
    window = {'start_seconds' => 2.0, 'end_seconds' => 2.5}
    table = ->(start_ns, end_ns) do
      <<~XML
        <node>
          <row><event-time>#{start_ns}</event-time><event-type>Begin</event-type>
            <signpost-name>Build workflow context</signpost-name><subsystem>com.revenuecat.workflow-profile</subsystem></row>
          <row><event-time>#{end_ns}</event-time><event-type>End</event-type>
            <signpost-name>Build workflow context</signpost-name><subsystem>com.revenuecat.workflow-profile</subsystem></row>
        </node>
      XML
    end
    first = table.call(2_100_000_000, 2_200_000_000)
    File.write(path, "<trace-query-result>#{first}#{first}</trace-query-result>")
    WorkflowTrace.verify_context_timing(path, window)

    second = table.call(2_300_000_000, 2_400_000_000)
    File.write(path, "<trace-query-result>#{first}#{second}</trace-query-result>")
    error = assert_raises(RuntimeError) { WorkflowTrace.verify_context_timing(path, window) }
    assert_includes error.message, 'Expected one first-screen context build'
  end

  def test_waits_for_the_matching_darwin_notification
    post = Fiddle::Function.new(Fiddle.dlopen('/usr/lib/libSystem.B.dylib')['notify_post'],
                                [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
    WorkflowTrace.recording_notification do |name, started|
      refute started.call
      assert_equal 0, post.call(name + '.unrelated')
      refute started.call
      assert_equal 0, post.call(name)
      WorkflowTrace.wait_for('test notification', timeout: 2, &started)
    end
  end

  def test_command_timeout_terminates_the_child_and_preserves_its_log
    log = File.join(@directory, 'command.log')
    error = assert_raises(RuntimeError) do
      @runner.run_logged([RbConfig.ruby, '-e', '$stdout.sync = true; puts Process.pid; sleep 10'], log, timeout: 0.2)
    end
    assert_includes error.message, 'Timed out'
    pid = Integer(File.read(log).strip)
    assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
  end

  private

  def capture_environment(name, overrides = {})
    app = File.join(@directory, 'app')
    FileUtils.mkdir_p(app)
    File.write(File.join(app, 'app'), 'fixture')
    commands = {
      ['plutil', '-convert', 'json', '-o', '-', File.join(app, 'Info.plist')] => JSON.generate({
        'CFBundleIdentifier' => WorkflowTrace::BUNDLE, 'REVENUECAT_API_KEY' => 'test_fixture',
        'WorkflowProfileBuild' => 'Release:-O: DEBUG', 'CFBundleExecutable' => 'app'
      }),
      ['xcrun', 'simctl', 'bootstatus', 'device', '-b'] => '',
      ['xcrun', 'simctl', 'install', 'device', app] => '',
      ['xcrun', 'simctl', 'get_app_container', 'device', WorkflowTrace::BUNDLE, 'data'] => @directory,
      ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'] => JSON.generate({
        'devices' => {'runtime' => [{'udid' => 'device', 'deviceTypeIdentifier' => 'iPhone'}]}
      }),
      ['xcrun', 'simctl', 'list', 'runtimes', '-j'] => JSON.generate({
        'runtimes' => [{'identifier' => 'runtime', 'buildversion' => 'build'}]
      }),
      ['maestro', '--version'] => '2.5.0',
      ['xcodebuild', '-version'] => 'Xcode 27.0', ['sysctl', '-n', 'hw.model'] => 'VirtualMac2,1',
      ['sysctl', '-in', 'machdep.cpu.brand_string'] => 'Apple M4 Pro',
      ['sysctl', '-n', 'hw.logicalcpu'] => '6',
      ['sw_vers', '-productVersion'] => '26.6.2', ['uname', '-m'] => 'arm64',
      ['git', 'rev-parse', 'HEAD'] => 'commit', ['git', 'status', '--porcelain'] => ''
    }
    commands.merge!(overrides)
    capture = File.join(@directory, name)
    @runner.stub(:output, ->(*args) { commands.fetch(args) }) do
      @runner.stub(:launch, ->(*) { raise 'Stop before capture' }) do
        error = assert_raises(RuntimeError) { @runner.record(capture) }
        assert_equal 'Stop before capture', error.message
      end
    end
    JSON.parse(File.read(File.join(capture, 'manifest.json'))).fetch('environment')
  end
end
