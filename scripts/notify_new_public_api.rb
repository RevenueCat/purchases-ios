#!/usr/bin/env ruby
# frozen_string_literal: true

# Posts a Slack message listing public API added to the api/ baselines between two refs.
# Exits quietly when there's nothing new. Prints the message without posting when
# SLACK_WEBHOOK_URL is unset, which makes it safe to run locally.
#
# Usage: BASE_SHA=<sha> HEAD_SHA=<sha> ruby scripts/notify_new_public_api.rb

require 'json'
require 'net/http'
require 'uri'
require_relative '../fastlane/api_diff_helper'

REPO_URL = ENV.fetch("REPO_URL", "https://github.com/RevenueCat/purchases-ios")

def git(*args)
  output = IO.popen(["git", *args], &:read)
  raise "git #{args.join(' ')} failed" unless $?.success?

  output
end

def source_link
  pr_number = ENV["PR_NUMBER"].to_s
  return ApiDiffHelper.pull_request_link(number: pr_number, title: ENV["PR_TITLE"].to_s, repo_url: REPO_URL) unless pr_number.empty?

  head = ENV.fetch("HEAD_SHA", "HEAD")
  ApiDiffHelper.source_link(
    subject: git("log", "-1", "--pretty=%s", head).strip,
    sha: git("rev-parse", "--short", head).strip,
    repo_url: REPO_URL
  )
end

def post_to_slack(request)
  response = Net::HTTP.post(URI.parse(request[:url]), request[:body].to_json, request[:headers])
  raise "Slack returned #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

  # chat.postMessage reports its own failures with a 200 and ok: false.
  body = JSON.parse(response.body) rescue nil
  raise "Slack rejected the message: #{body['error']}" if body.is_a?(Hash) && body["ok"] == false
end

head = ENV.fetch("HEAD_SHA", "HEAD")

# A force push or a brand new branch reports an all-zero or unknown base, so fall back to
# the previous commit rather than failing the run.
def resolve_base(base, head)
  return "#{head}^" if base.empty? || base.match?(/\A0+\z/)
  return base if system("git", "cat-file", "-e", "#{base}^{commit}", out: File::NULL, err: File::NULL)

  warn "Base #{base} is not available, falling back to #{head}^"
  "#{head}^"
end

base = resolve_base(ENV.fetch("BASE_SHA", "HEAD^"), head)

# Three dots so a pull request is compared against its merge base, not the tip of main.
diff = git("diff", "--unified=0", "#{base}...#{head}", "--", "api")
changes = ApiDiffHelper.new_api_changes(diff)
breaks = ApiDiffHelper.breaking_additions(diff) { |path| git("show", "#{head}:#{path}").lines }

unless ApiDiffHelper.reportable?(changes, breaks)
  puts "No public API changes between #{base} and #{head}, nothing to notify"
  exit 0
end

# A pull request number is only set for pull request events; a push to main has none.
status = ENV["PR_NUMBER"].to_s.empty? ? :landed : :up_for_review
message = ApiDiffHelper.api_report_message(changes, breaks_by_module: breaks, source: source_link, status: status)
puts message

request = ApiDiffHelper.slack_post_request(
  message,
  webhook_url: ENV["SLACK_WEBHOOK_URL"],
  bot_token: ENV["SLACK_BOT_TOKEN"],
  channel: ENV["SLACK_CHANNEL"]
)

if request.nil?
  puts "\nNo Slack credential configured (SLACK_WEBHOOK_URL, or SLACK_BOT_TOKEN with " \
       "SLACK_CHANNEL), skipping the notification"
  exit 0
end

post_to_slack(request)
puts "\nPosted to Slack"
