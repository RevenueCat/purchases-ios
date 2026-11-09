require 'open3'

module PerformanceBaselineHelper
  def self.push
    branch = ENV.fetch('CIRCLE_BRANCH')
    revision = ENV.fetch('CIRCLE_SHA1')
    baseline = 'Tests/PerformanceTests/Baselines.json'

    if branch == 'main' || !ENV.fetch('CIRCLE_TAG', '').empty?
      raise 'Baseline updates require a PR branch.'
    end

    git('check-ref-format', "refs/heads/#{branch}")
    git('fetch', 'origin', "refs/heads/#{branch}")
    unless git('rev-parse', 'FETCH_HEAD') == revision && git('rev-parse', 'HEAD') == revision
      raise 'The PR branch changed. Run record-performance again.'
    end

    if git('diff', '--name-only', 'HEAD', '--', baseline).empty?
      puts 'No baseline changes to commit.'
      return
    end

    puts git('commit', '--only', '-m', 'Update performance baselines', '--', baseline)
    puts git('push', 'origin', "HEAD:refs/heads/#{branch}")
  end

  def self.git(*arguments)
    output, status = Open3.capture2e('git', *arguments)
    raise output unless status.success?

    output.strip
  end
  private_class_method :git
end
