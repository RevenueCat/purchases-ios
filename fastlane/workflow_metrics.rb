require 'json'
require 'nokogiri'

module WorkflowMetrics
  METRIC = 'sampled_main_thread_cpu_ms_per_journey_v2'
  TOTAL = 'Total journey'
  MIN_ITERATIONS = 6
  POLICY = {'confidence' => 0.99, 'resamples' => 10_000, 'minimum_ms' => 10, 'minimum_percent' => 10}.freeze

  def self.measure_cpu(path, target_pid, windows)
    references = {}
    samples = windows.to_h { |window| [window.fetch('action'), 0.0] }
    resolve = lambda do |element|
      raise 'Missing CPU sample field.' unless element
      return references.fetch(element['ref']) { raise 'Unresolved Instruments XML reference.' } if element['ref']
      value = {text: element.text, format: element['fmt']}
      value[:pid] = resolve.call(element.at_xpath('pid'))[:text] if element.name == 'process'
      value
    end
    File.open(path) do |file|
      Nokogiri::XML::Reader(file).each do |node|
        next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT && node.name == 'row'
        row = Nokogiri::XML.fragment(node.outer_xml).at_xpath('row')
        row.xpath('.//*[@id]').each do |element|
          references[element['id']] = resolve.call(element) if %w[sample-time thread process pid thread-state weight].include?(element.name)
        end
        process = resolve.call(row.at_xpath('process'))
        pid = process[:pid]
        thread = resolve.call(row.at_xpath('thread'))[:format].to_s
        state = resolve.call(row.at_xpath('thread-state'))[:format]
        next unless pid == target_pid.to_s && thread.start_with?('Main Thread ') && state == 'Running'
        timestamp = Integer(resolve.call(row.at_xpath('sample-time'))[:text]) / 1e9
        weight = Integer(resolve.call(row.at_xpath('weight'))[:text]) / 1e6
        raise 'Invalid CPU sample weight.' unless weight.positive?
        windows.each do |window|
          samples[window['action']] += weight if timestamp >= window['start_seconds'] && timestamp < window['end_seconds']
        end
      end
    end
    raise 'An action has no main-thread CPU samples.' if samples.empty? || samples.values.any? { |value| value <= 0 }
    samples
  end

  def self.median(values)
    sorted = values.sort
    middle = sorted.length / 2
    sorted.length.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
  end

  def self.summarize(manifest, samples)
    unless manifest['status'] == 'complete' && samples.length >= MIN_ITERATIONS
      raise "At least #{MIN_ITERATIONS} complete iterations are required."
    end
    actions = samples.first.keys
    if actions.empty? || actions.include?(TOTAL) || samples.any? { |sample| sample.keys.sort != actions.sort }
      raise 'Incomplete action samples.'
    end
    statistics = [TOTAL, *actions].to_h do |action|
      values = samples.map { |sample| action == TOTAL ? sample.values.sum : sample[action] }
      raise 'Invalid CPU measurement.' unless values.all? { |value| value.is_a?(Numeric) && value.finite? && value.positive? }
      center = median(values)
      [action, {'median_ms' => center, 'min_ms' => values.min, 'max_ms' => values.max,
                'mad_ms' => median(values.map { |value| (value - center).abs })}]
    end
    manifest.merge('metric' => METRIC, 'samples' => samples, 'statistics' => statistics, 'policy' => POLICY)
  end

  def self.compare(current, baseline)
    %w[metric policy environment workload].each do |key|
      if current.fetch(key) != baseline.fetch(key) || (key == 'metric' && current[key] != METRIC)
        raise "Incompatible benchmark #{key}."
      end
    end
    raise 'Unsupported benchmark policy.' unless current['policy'] == POLICY
    current = summarize(current, current.fetch('samples'))
    baseline = summarize(baseline, baseline.fetch('samples'))
    raise 'Incompatible benchmark actions.' unless current['statistics'].keys.sort == baseline['statistics'].keys.sort
    before = baseline['samples'].map { |sample| sample.values.sum }
    after = current['samples'].map { |sample| sample.values.sum }
    reference, measured = median(before), median(after)
    # Ruby's multiword seed preserves the original Python seed 0 sequence.
    random = Random.new(2**32)
    differences = Array.new(POLICY['resamples']) do
      median(Array.new(after.length) { after[(random.rand * after.length).floor] }) -
        median(Array.new(before.length) { before[(random.rand * before.length).floor] })
    end.sort
    tail = ((1 - POLICY['confidence']) / 2 * differences.length).round
    lower, upper = differences[tail], differences[-tail - 1]
    tolerance = [POLICY['minimum_ms'], reference * POLICY['minimum_percent'] / 100.0].max
    verdict = if lower > tolerance
                'regression'
              elsif upper < -tolerance
                'improvement'
              elsif lower >= -tolerance && upper <= tolerance
                'unchanged'
              else
                'inconclusive'
              end
    {'baseline_median_ms' => reference, 'current_median_ms' => measured,
     'delta_ms' => measured - reference, 'delta_percent' => 100.0 * (measured - reference) / reference,
     'interval_ms' => [lower, upper], 'tolerance_ms' => tolerance, 'verdict' => verdict}
  end

  def self.report(summary, baseline = nil)
    unless baseline
      lines = summary.fetch('statistics').map do |action, values|
        format('%s: median %.2f ms, range %.2f to %.2f ms', action, values['median_ms'], values['min_ms'], values['max_ms'])
      end
      return [("Initial baseline. No performance comparison.\n" + lines.join("\n") + "\n"), 0]
    end
    change = compare(summary, baseline)
    summary['comparison'] = change
    summary['baseline_commit'] = baseline.fetch('commit')
    lines = ['Action | baseline ms | current ms']
    summary['statistics'].each do |action, values|
      lines << format('%s | %.2f | %.2f', action, baseline['statistics'][action]['median_ms'], values['median_ms'])
    end
    lines << format('Total journey: %+.1f%%, 99%% interval of change [%+.2f, %+.2f] ms: %s',
                    change['delta_percent'], *change['interval_ms'], change['verdict'])
    [lines.join("\n") + "\n", {'regression' => 1, 'inconclusive' => 2}.fetch(change['verdict'], 0)]
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'Usage: bundle exec ruby fastlane/workflow_metrics.rb CURRENT.json BASELINE.json' unless ARGV.length == 2
  text, code = WorkflowMetrics.report(*ARGV.map { |path| JSON.parse(File.read(path)) })
  puts text
  exit code
end
