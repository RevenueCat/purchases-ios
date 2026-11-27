require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'yaml'
require 'rbconfig'

class PerformanceBaselineHelperTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  BASELINE = 'Tests/PerformanceTests/Baselines.json'

  def command(*args, env: {}, directory: @checkout)
    output, status = Open3.capture2e(env, *args, chdir: directory)
    assert status.success?, output
    output.strip
  end

  def setup
    @temporary = Dir.mktmpdir
    @remote = File.join(@temporary, 'remote.git')
    @checkout = File.join(@temporary, 'checkout')
    command('git', 'init', '--bare', @remote, directory: @temporary)
    command('git', 'clone', @remote, @checkout, directory: @temporary)
    command('git', 'config', 'user.name', 'Test')
    command('git', 'config', 'user.email', 'test@example.com')
    command('git', 'checkout', '-b', 'test-pr')
    FileUtils.mkdir_p(File.join(@checkout, File.dirname(BASELINE)))
    File.write(File.join(@checkout, BASELINE), "{}\n")
    File.write(File.join(@checkout, 'other.txt'), 'original')
    command('git', 'add', '.')
    command('git', 'commit', '-m', 'Initial')
    command('git', 'push', 'origin', 'test-pr')
    @head = command('git', 'rev-parse', 'HEAD')
  end

  def teardown
    FileUtils.remove_entry(@temporary)
  end

  def publish
    Open3.capture2e({'CIRCLE_BRANCH' => 'test-pr', 'CIRCLE_SHA1' => @head},
                   RbConfig.ruby, '-r', File.join(ROOT, 'fastlane/performance_baseline_helper.rb'),
                   '-e', 'PerformanceBaselineHelper.push', chdir: @checkout)
  end

  def test_pushes_only_baseline_and_skips_unchanged_result
    File.write(File.join(@checkout, BASELINE), '{"peakMemoryMiB":42}')
    File.write(File.join(@checkout, 'other.txt'), 'unrelated')
    command('git', 'add', 'other.txt')
    output, status = publish
    assert status.success?, output
    assert_equal BASELINE, command('git', '--git-dir', @remote, 'diff-tree', '--no-commit-id', '--name-only', '-r', 'test-pr')
    assert_equal '{"peakMemoryMiB":42}', command('git', '--git-dir', @remote, 'show', "test-pr:#{BASELINE}")
    @head = command('git', 'rev-parse', 'HEAD')
    output, status = publish
    assert status.success?, output
    assert_equal @head, command('git', '--git-dir', @remote, 'rev-parse', 'test-pr')
  end

  def test_rejects_results_after_branch_changes
    command('git', 'commit', '--allow-empty', '-m', 'New PR commit')
    command('git', 'push', 'origin', 'test-pr')
    remote_head = command('git', 'rev-parse', 'HEAD')
    command('git', 'checkout', '--detach', @head)
    File.write(File.join(@checkout, BASELINE), '{"peakMemoryMiB":42}')
    output, status = publish
    refute status.success?, output
    assert_includes output, 'branch changed'
    assert_equal remote_head, command('git', '--git-dir', @remote, 'rev-parse', 'test-pr')
  end

  def workflow_jobs(workflow)
    config = YAML.safe_load(File.read(File.join(ROOT, '.circleci/default_config.yml')), aliases: true)
    config.fetch('workflows').fetch(workflow).fetch('jobs').to_h do |job|
      job.is_a?(Hash) ? [job.values.first['name'] || job.keys.first, job.values.first || {}] : [job, {}]
    end
  end

  def pr_workflow_jobs
    workflow_jobs('run-all-tests')
  end

  def test_merge_gates_require_danger_and_the_export_dry_run
    pr_gate = pr_workflow_jobs.fetch('all-tasks-succeeded').fetch('requires')
    tagging = workflow_jobs('release-or-main').fetch('revenuecat/tag-current-branch').fetch('requires')
    [pr_gate, tagging].each do |requires|
      assert_includes requires, 'danger'
      assert_includes requires, 'export-to-public-dry-run'
    end
  end

  def test_release_pr_merge_gate_waits_for_the_tag
    assert_equal %w[revenuecat/tag-current-branch], workflow_jobs('release-or-main').fetch('all-tasks-succeeded').fetch('requires')
    refute_includes workflow_jobs('deploy-tag').keys, 'all-tasks-succeeded'
  end

  def test_pr_merge_gate_requires_the_memory_benchmark
    assert_includes pr_workflow_jobs.fetch('all-tasks-succeeded').fetch('requires'), 'performance-tests'
  end

  def test_pr_merge_gate_does_not_wait_for_the_full_suite
    jobs = pr_workflow_jobs
    jobs.fetch('all-tasks-succeeded').fetch('requires').each do |required|
      refute_includes jobs.fetch(required).fetch('requires', []), 'approve-full-tests', "#{required} only runs after approve-full-tests"
    end
  end

  def test_requested_job_enables_record_and_push_with_boolean_parameters
    command('node', '.circleci/generate-requested-jobs-config.js', env: {'REQUESTED_JOBS' => 'record-performance'}, directory: ROOT)
    config = YAML.safe_load(File.read('/tmp/requested-jobs-config.yml'), aliases: true)
    job = config.fetch('workflows').fetch('on-demand-jobs').fetch('jobs').first.fetch('performance-tests')
    assert_equal 'record-performance', job.fetch('name')
    assert_equal true, job.fetch('record_baselines')
    assert_equal true, job.fetch('push_baselines')
  end
end
