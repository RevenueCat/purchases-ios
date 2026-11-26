require 'digest'
require 'fileutils'
require 'fiddle/import'
require 'open3'
require 'securerandom'
require 'time'
require 'timeout'
require_relative 'workflow_metrics'

class WorkflowTrace
  ROOT = File.expand_path('..', __dir__)
  BUNDLE = 'com.revenuecat.maestro.ios'
  FLOW = File.join(ROOT, 'Projects/AutomatedSDKTestsApp/maestro/performance/default_workflows.yaml')
  PROFILE = File.join(ROOT, 'Projects/AutomatedSDKTestsApp/AutomatedSDKTestsApp/Sources/AutomatedSDKTestsApp/WorkflowProfile.swift')

  def self.notification_library
    @notification_library ||= Module.new do
      extend Fiddle::Importer
      dlload '/usr/lib/libSystem.B.dylib'
      extern 'int notify_register_file_descriptor(const char*, int*, int, int*)'
      extern 'int notify_cancel(int)'
    end
  end

  def initialize(device:, output:, app:, baseline: nil, iterations: WorkflowMetrics::MIN_ITERATIONS)
    @device, @output, @app = device, File.expand_path(output), File.expand_path(app)
    @baseline = File.expand_path(baseline) if baseline
    @iterations = Integer(iterations)
  end

  def run
    raise "At least #{WorkflowMetrics::MIN_ITERATIONS} iterations are required." if @iterations < WorkflowMetrics::MIN_ITERATIONS
    Dir.mkdir(@output)
    baseline = read_json(File.join(@baseline, 'summary.json')) if @baseline
    write_json(File.join(@output, 'baseline.json'), baseline) if baseline
    symbols = File.join(@output, 'symbols')
    Dir.mkdir(symbols)
    FileUtils.cp_r(Dir.glob(File.join(File.dirname(@app), '*.dSYM')), symbols)
    samples, reference = [], nil
    @iterations.times do |iteration|
      puts "Iteration #{iteration + 1}/#{@iterations}"
      directory = File.join(@output, format('iteration-%02d', iteration + 1))
      manifest, sample = record(directory)
      self.class.require_compatible(manifest, reference || baseline || manifest,
                                    reference ? format('iteration-%02d', iteration) : 'baseline')
      if reference && %w[commit executable_sha256 sdk_diff_sha256].any? { |key| manifest[key] != reference[key] }
        raise 'The app or SDK changed between iterations.'
      end
      reference = manifest
      samples << sample
    end
    summary = WorkflowMetrics.summarize(reference, samples)
    text, code = WorkflowMetrics.report(summary, baseline)
    write_json(File.join(@output, 'summary.json'), summary)
    File.write(File.join(@output, 'comparison.txt'), text)
    puts text
    code
  end

  def self.require_compatible(current, baseline, reference_name = 'baseline')
    raise "The #{reference_name} did not complete successfully." unless baseline['status'] == 'complete'
    %w[workload environment].each do |key|
      next if current.fetch(key) == baseline.fetch(key)
      differences = (current[key].keys | baseline[key].keys).sort.filter_map do |field|
        before, after = baseline[key].fetch(field, '<missing>'), current[key].fetch(field, '<missing>')
        "#{key}.#{field}: #{JSON.generate(before)} -> #{JSON.generate(after)}" unless before == after
      end
      raise "Metadata differs from #{reference_name}:\n#{differences.join("\n")}"
    end
  end

  def self.action_windows(commands, trace_start_seconds)
    ordered = commands.sort_by { |entry| entry.fetch('metadata').fetch('timestamp') }
    windows = ordered.each_with_index.filter_map do |entry, index|
      tap = entry.fetch('command')['tapOnElement']
      next unless tap
      destination = ordered[index + 1]
      unless destination&.dig('command', 'assertConditionCommand', 'condition', 'visible')
        raise 'Expected a destination visibility check after each tap.'
      end
      metadata = entry.fetch('metadata')
      visible = destination.fetch('metadata')
      unless [metadata, visible].all? { |step| step['status'] == 'COMPLETED' && step.fetch('duration') >= 0 }
        raise 'The Maestro tap or visibility check did not complete.'
      end
      start_ms = metadata.fetch('timestamp') - trace_start_seconds * 1000
      end_ms = visible.fetch('timestamp') + visible.fetch('duration') - trace_start_seconds * 1000
      raise 'The Maestro action preceded the trace.' if start_ms.negative?
      {'action' => tap.fetch('selector').fetch('textRegex'), 'start_seconds' => start_ms / 1000.0,
       'end_seconds' => end_ms / 1000.0}
    end
    unless windows.map { |window| window['action'] } == ['Present Paywall', 'Continue 1/3', 'Continue 2/3']
      raise 'Expected presentation and two forward actions.'
    end
    windows
  end

  def self.verify_context_timing(signposts, presentation)
    xml = Nokogiri::XML(File.read(signposts))
    definitions = xml.xpath('//*[@id]').to_h { |node| [node['id'], node] }
    value = ->(node) { node && (node['ref'] ? definitions.fetch(node['ref']) : node).text }
    events = xml.xpath('//row').filter_map do |row|
      next unless value.call(row.at_xpath('signpost-name')) == 'Build workflow context'
      next unless value.call(row.at_xpath('subsystem')) == 'com.revenuecat.workflow-profile'
      [value.call(row.at_xpath('event-type')), Integer(value.call(row.at_xpath('event-time'))) / 1e9]
    end
    # Instruments can export the same signpost in multiple Points of Interest tables.
    events.uniq!
    raise 'Expected one first-screen context build in the trace.' unless events.map(&:first) == %w[Begin End]
    window = presentation.fetch('start_seconds')..presentation.fetch('end_seconds')
    unless events.all? { |_, time| window.cover?(time) }
      raise 'First-screen context construction fell outside the presentation window.'
    end
  end

  def self.recording_notification
    name = "com.revenuecat.workflow-profile.#{SecureRandom.hex}"
    descriptor, token = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT, Fiddle::RUBY_FREE), Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT, Fiddle::RUBY_FREE)
    status = notification_library.notify_register_file_descriptor(name, descriptor, 0, token)
    raise "Cannot register the Instruments start notification: #{status}" unless status.zero?
    begin
      io = IO.for_fd(descriptor[0, Fiddle::SIZEOF_INT].unpack1('i'), autoclose: false)
      yield name, -> { !IO.select([io], nil, nil, 0).nil? }
    ensure
      notification_library.notify_cancel(token[0, Fiddle::SIZEOF_INT].unpack1('i'))
    end
  end

  def self.wait_for(description, timeout: 60)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    loop do
      return if yield
      raise "Timed out: #{description}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.2
    end
  end

  def output(*command)
    text, status = Open3.capture2(*command, chdir: ROOT)
    raise "#{command.first} failed with exit code #{status.exitstatus}." unless status.success?
    text.strip
  end

  def run_logged(command, path, timeout: 180)
    File.open(path, 'w') do |log|
      pid = Process.spawn(*command, chdir: ROOT, out: log, err: log)
      process = Process.detach(pid)
      begin
        status = Timeout.timeout(timeout) { process.value }
        raise "#{command.first} failed with exit code #{status.exitstatus}. See #{path}." unless status.success?
      rescue Timeout::Error
        Process.kill('KILL', pid) if process.alive?
        process.join
        raise "Timed out: #{command.first}. See #{path}."
      end
    end
  end

  def stop_trace(process)
    Process.kill('INT', process.pid) if process.alive?
    begin
      status = Timeout.timeout(60) { process.value }
    rescue Timeout::Error
      Process.kill('KILL', process.pid) if process.alive?
      process.join
      raise 'Instruments did not finish the trace.'
    end
    raise "Instruments failed with exit code #{status.exitstatus}. See instruments.log." unless status.success?
  end

  def record(directory)
    Dir.mkdir(directory)
    info = JSON.parse(output('plutil', '-convert', 'json', '-o', '-', File.join(@app, 'Info.plist')))
    unless info['CFBundleIdentifier'] == BUNDLE && info.fetch('REVENUECAT_API_KEY', '').start_with?('test_')
      raise 'Use the AutomatedSDK app configured with the AutomatedSDK Test Store key.'
    end
    build = info.fetch('WorkflowProfileBuild', '')
    raise 'Build with bundle exec fastlane ios workflow_trace to use Release optimization.' unless build.start_with?('Release:-O:')
    output('xcrun', 'simctl', 'bootstatus', @device, '-b')
    output('xcrun', 'simctl', 'install', @device, @app)
    container = output('xcrun', 'simctl', 'get_app_container', @device, BUNDLE, 'data')
    identity = File.join(container, 'Library/Caches/workflow-profile.json')
    devices = JSON.parse(output('xcrun', 'simctl', 'list', 'devices', 'available', '-j')).fetch('devices')
    runtime, entries = devices.find { |_, entries| entries.any? { |device| device['udid'] == @device } }
    device = entries.find { |item| item['udid'] == @device }
    runtimes = JSON.parse(output('xcrun', 'simctl', 'list', 'runtimes', '-j')).fetch('runtimes')
    runtime_info = runtimes.find { |item| item['identifier'] == runtime }
    environment = {
      'xcode' => output('xcodebuild', '-version'), 'maestro' => output('maestro', '--version').lines.last.strip,
      'host_model' => output('sysctl', '-n', 'hw.model'), 'host_os' => output('sw_vers', '-productVersion'),
      'cpu_model' => output('sysctl', '-in', 'machdep.cpu.brand_string'),
      'logical_cpus' => Integer(output('sysctl', '-n', 'hw.logicalcpu')),
      'ci_resource_class' => ENV['RC_CI_RESOURCE_CLASS'],
      'architecture' => output('uname', '-m'), 'simulator_runtime' => runtime,
      'simulator_build' => runtime_info.fetch('buildversion'), 'model' => device.fetch('deviceTypeIdentifier'),
      'build' => build, 'template' => 'Time Profiler', 'cache' => 'one unrecorded journey before capture',
      'flow_sha256' => Digest::SHA256.file(FLOW).hexdigest, 'profile_sha256' => Digest::SHA256.file(PROFILE).hexdigest
    }
    diff, status = Open3.capture2('git', 'diff', 'HEAD', '--', 'Sources', 'RevenueCatUI', chdir: ROOT)
    raise 'Cannot read the SDK diff.' unless status.success?
    manifest = {'status' => 'started', 'commit' => output('git', 'rev-parse', 'HEAD'),
                'dirty' => !output('git', 'status', '--porcelain').empty?, 'environment' => environment,
                'sdk_diff_sha256' => Digest::SHA256.hexdigest(diff),
                'executable_sha256' => Digest::SHA256.file(File.join(@app, info.fetch('CFBundleExecutable'))).hexdigest}
    manifest_path = File.join(directory, 'manifest.json')
    write_json(manifest_path, manifest)
    begin
      puts 'Warm up default_workflows.'
      _, manifest['workload'] = launch(directory, identity, 'warmup')
      journey(directory, 'warmup')
      pid, workload = launch(directory, identity, 'recorded')
      raise 'The workflow changed after warm-up.' unless workload == manifest['workload']
      write_json(manifest_path, manifest)
      trace = File.join(directory, 'workflow.trace')
      puts 'Record the workflow journey.'
      self.class.recording_notification do |notification, notified|
        File.open(File.join(directory, 'instruments.log'), 'w') do |log|
          trace_pid = Process.spawn('xcrun', 'xctrace', 'record', '--template', 'Time Profiler',
                                    '--device', @device, '--attach', pid, '--output', trace,
                                    '--time-limit', '180s', '--no-prompt', '--notify-tracing-started', notification,
                                    chdir: ROOT, out: log, err: log)
          process = Process.detach(trace_pid)
          begin
            self.class.wait_for('Instruments recording') do
              raise 'Instruments exited before capture. See instruments.log.' unless process.alive?
              notified.call
            end
            journey(directory, 'recorded')
            raise 'Instruments stopped before the journey completed.' unless process.alive?
          ensure
            stop_trace(process)
          end
        end
      end
      run_logged(['xcrun', 'xctrace', 'export', '--input', trace, '--toc'], File.join(directory, 'trace-toc.xml'))
      %w[time-profile os-signpost].each do |schema|
        run_logged(['xcrun', 'xctrace', 'export', '--input', trace, '--xpath',
                    "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"#{schema}\"]"], File.join(directory, "#{schema}.xml"))
      end
      trace_start = Nokogiri::XML(File.read(File.join(directory, 'trace-toc.xml'))).at_xpath('//summary/start-date').text
      command_logs = Dir.glob(File.join(directory, 'recorded/**/commands-*.json'), File::FNM_DOTMATCH)
      raise 'Expected one Maestro command log.' unless command_logs.length == 1
      windows = self.class.action_windows(read_json(command_logs.first), Time.iso8601(trace_start).to_r.to_f)
      self.class.verify_context_timing(File.join(directory, 'os-signpost.xml'), windows.first)
      write_json(File.join(directory, 'actions.json'), {
        'description' => 'From tap start to destination visibility confirmation, relative to trace start.',
        'windows' => windows
      })
      sample = WorkflowMetrics.measure_cpu(File.join(directory, 'time-profile.xml'), pid, windows)
      manifest['status'] = 'complete'
      puts "Trace saved to #{trace}"
      [manifest, sample]
    rescue StandardError, Interrupt => error
      manifest['status'] = 'failed'
      manifest['error'] = error.message
      raise
    ensure
      write_json(manifest_path, manifest)
    end
  end

  def launch(directory, identity, name)
    FileUtils.rm_f(identity)
    launched = output('xcrun', 'simctl', 'launch', '--terminate-running-process',
                      "--stdout=#{File.join(directory, "#{name}-app.stdout.log")}",
                      "--stderr=#{File.join(directory, "#{name}-app.stderr.log")}", @device, BUNDLE,
                      '-e2e_test_flow', 'open_workflow', '-workflow_offering_identifier', 'default_workflows',
                      '-workflow_profile', 'YES', '-app_user_id', 'workflow-instruments',
                      '-AppleLanguages', '(en)', '-AppleLocale', 'en_US')
    pid = launched.split(': ').last
    self.class.wait_for('workflow configuration', timeout: 90) { File.exist?(identity) }
    workload = read_json(identity)
    raise 'Disable Reduce Motion on the simulator before this run.' if workload['reduce_motion']
    [pid, workload]
  end

  def journey(directory, name)
    run_logged(['maestro', '--device', @device, 'test', '--format', 'JUNIT',
                '--output', File.join(directory, "#{name}.xml"), '--debug-output', File.join(directory, name), FLOW],
               File.join(directory, "#{name}.log"))
  end

  def read_json(path)
    JSON.parse(File.read(path))
  end

  def write_json(path, value)
    File.write(path, JSON.pretty_generate(value) + "\n")
  end
end
