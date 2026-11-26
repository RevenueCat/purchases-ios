require 'minitest/autorun'
require 'tmpdir'
require 'open3'
require 'rbconfig'
require_relative 'workflow_metrics'

class WorkflowMetricsTest < Minitest::Test
  def summary(values)
    WorkflowMetrics.summarize({'status' => 'complete', 'environment' => {'model' => 'iPhone'},
                              'workload' => {'blob_ref' => 'fixture'}, 'commit' => 'abc'},
                             values.map { |value| {'action' => value} })
  end

  def test_sample_references_thread_selection_and_window_boundaries
    xml = <<~XML
      <trace-query-result><node>
      <row><sample-time>100000000</sample-time><thread id="t" fmt="Main Thread 0x1"/>
      <process id="p"><pid>42</pid></process><thread-state id="s" fmt="Running"/><weight id="w">2000000</weight></row>
      <row><sample-time>200000000</sample-time><thread ref="t"/><process ref="p"/>
      <thread-state ref="s"/><weight ref="w"/></row>
      <row><sample-time>300000000</sample-time><thread fmt="Worker"/><process ref="p"/>
      <thread-state ref="s"/><weight>9000000</weight></row>
      <row><sample-time>400000000</sample-time><thread ref="t"/><process><pid>99</pid></process>
      <thread-state ref="s"/><weight>9000000</weight></row>
      <row><sample-time>500000000</sample-time><thread ref="t"/><process ref="p"/>
      <thread-state fmt="Waiting"/><weight>9000000</weight></row>
      <row><sample-time>1000000000</sample-time><thread ref="t"/><process ref="p"/>
      <thread-state ref="s"/><weight>3000000</weight></row>
      </node></trace-query-result>
    XML
    windows = [{'action' => 'present', 'start_seconds' => 0.1, 'end_seconds' => 1},
               {'action' => 'next', 'start_seconds' => 1, 'end_seconds' => 2}]
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'samples.xml')
      File.write(path, xml)
      assert_equal({'present' => 4.0, 'next' => 3.0}, WorkflowMetrics.measure_cpu(path, '42', windows))
      File.write(path, xml.sub('ref="w"', 'ref="missing"'))
      assert_raises(RuntimeError) { WorkflowMetrics.measure_cpu(path, '42', windows) }
      File.write(path, '<trace-query-result/>')
      assert_raises(RuntimeError) { WorkflowMetrics.measure_cpu(path, '42', windows) }
    end
  end

  def test_invalid_or_incompatible_summaries_are_rejected
    assert_raises(RuntimeError) { summary([100] * 5) }
    [Float::NAN, Float::INFINITY, -1, 0].each do |value|
      assert_raises(RuntimeError) { summary([100] * 5 + [value]) }
    end
    baseline = summary([100] * 6)
    %w[environment workload metric policy].each do |key|
      current = Marshal.load(Marshal.dump(baseline))
      current[key] = 'changed'
      assert_raises(RuntimeError) { WorkflowMetrics.compare(current, baseline) }
    end
  end

  def test_command_exit_status_distinguishes_changes_and_uncertainty
    Dir.mktmpdir do |directory|
      baseline = File.join(directory, 'baseline.json')
      current = File.join(directory, 'current.json')
      File.write(baseline, JSON.generate(summary([98, 100, 102, 99, 101, 100])))
      [[[99, 101, 100, 98, 102, 100], 0, 'unchanged'], [[105] * 6, 0, 'unchanged'],
       [[148, 150, 152, 149, 151, 150], 1, 'regression'], [[50] * 6, 0, 'improvement'],
       [[60, 80, 100, 100, 120, 150], 2, 'inconclusive']].each do |values, code, verdict|
        File.write(current, JSON.generate(summary(values)))
        text, status = Open3.capture2e(RbConfig.ruby, File.join(__dir__, 'workflow_metrics.rb'), current, baseline)
        assert_equal code, status.exitstatus, text
        assert_includes text, verdict
      end
    end
  end

  def test_preserves_saved_baseline_comparison
    baseline = summary([785, 767, 796, 772, 751, 766])
    current = summary([758, 806, 748, 765, 776, 779])
    comparison = WorkflowMetrics.compare(current, baseline)
    assert_equal [-32.5, 36.5], comparison['interval_ms']
    assert_equal 'unchanged', comparison['verdict']
  end

  def test_total_controls_result_and_keeps_step_diagnostics
    manifest = {'status' => 'complete', 'environment' => {}, 'workload' => {}, 'commit' => 'abc'}
    baseline = WorkflowMetrics.summarize(manifest, [{'first' => 100, 'second' => 200}] * 6)
    current = WorkflowMetrics.summarize(manifest, [{'first' => 200, 'second' => 100}] * 6)
    text, code = WorkflowMetrics.report(current, baseline)
    assert_equal 0, code
    assert_equal 'unchanged', current['comparison']['verdict']
    assert_equal 300, current['statistics']['Total journey']['median_ms']
    assert_equal 200, current['statistics']['first']['median_ms']
    refute_includes text, 'regression'
    slower = WorkflowMetrics.summarize(manifest, [{'first' => 200, 'second' => 200}] * 6)
    assert_equal 1, WorkflowMetrics.report(slower, baseline).last
  end
end
