#!/usr/bin/env ruby

require "fileutils"
require "json"
require "open3"
require "optparse"

class PrivateSpecPublisher
  SAFE_SEGMENT = /\A[A-Za-z0-9][A-Za-z0-9_.+-]*\z/.freeze

  def initialize(argv)
    @repo_root = File.expand_path("..", __dir__)
    @write = false
    @github_output = false

    OptionParser.new do |opts|
      opts.banner = "Usage: private_spec_publisher.rb --podspec PATH --pod NAME --version VERSION [--dry-run|--write]"

      opts.on("--podspec PATH", "Generated podspec to publish") { |value| @podspec_path = value }
      opts.on("--pod NAME", "Expected pod name") { |value| @requested_name = value }
      opts.on("--version VERSION", "Expected pod version") { |value| @requested_version = value }
      opts.on("--repo-root PATH", "Spec repository root") { |value| @repo_root = File.expand_path(value) }
      opts.on("--dry-run", "Validate and print the destination without writing") { @write = false }
      opts.on("--write", "Copy the podspec into Specs/<Pod>/<version>/") { @write = true }
      opts.on("--github-output", "Append destination metadata to $GITHUB_OUTPUT") { @github_output = true }
    end.parse!(argv)
  end

  def run
    validate_required_options

    spec = parse_podspec
    pod_name = spec.fetch("name").to_s
    version = spec.fetch("version").to_s

    validate_segment!("pod name", pod_name)
    validate_segment!("version", version)
    validate_matches!("pod name", @requested_name, pod_name)
    validate_matches!("version", @requested_version, version)

    destination = File.join(@repo_root, "Specs", pod_name, version, "#{pod_name}.podspec")
    changed = destination_changed?(destination)

    if @write
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(@podspec_path, destination)
    end

    puts "pod: #{pod_name}"
    puts "version: #{version}"
    puts "destination: #{relative_path(destination)}"
    puts "mode: #{@write ? "write" : "dry-run"}"
    puts "changed: #{changed}"

    write_github_output(pod_name, version, destination, changed)
  end

  private

  def validate_required_options
    missing = []
    missing << "--podspec" unless @podspec_path
    missing << "--pod" unless @requested_name
    missing << "--version" unless @requested_version
    abort("missing required option(s): #{missing.join(", ")}") unless missing.empty?
    abort("podspec not found: #{@podspec_path}") unless File.file?(@podspec_path)
    abort("repo root not found: #{@repo_root}") unless Dir.exist?(@repo_root)
  end

  def parse_podspec
    stdout, stderr, status = Open3.capture3("pod", "ipc", "spec", @podspec_path)
    abort("podspec parse failed:\n#{stderr}") unless status.success?

    JSON.parse(stdout)
  rescue Errno::ENOENT
    abort("pod command not found. Install CocoaPods before running this publisher.")
  rescue JSON::ParserError => error
    abort("podspec parse output was not valid JSON: #{error.message}")
  end

  def validate_segment!(label, value)
    return if value.match?(SAFE_SEGMENT)

    abort("invalid #{label}: #{value.inspect}")
  end

  def validate_matches!(label, requested, parsed)
    return if requested.to_s == parsed.to_s

    abort("#{label} mismatch: requested #{requested.inspect}, parsed #{parsed.inspect}")
  end

  def destination_changed?(destination)
    return true unless File.file?(destination)

    File.binread(destination) != File.binread(@podspec_path)
  end

  def relative_path(path)
    path.delete_prefix("#{@repo_root}/")
  end

  def write_github_output(pod_name, version, destination, changed)
    return unless @github_output && ENV["GITHUB_OUTPUT"]

    File.open(ENV["GITHUB_OUTPUT"], "a") do |file|
      file.puts("pod_name=#{pod_name}")
      file.puts("version=#{version}")
      file.puts("destination=#{relative_path(destination)}")
      file.puts("changed=#{changed}")
    end
  end
end

PrivateSpecPublisher.new(ARGV).run
