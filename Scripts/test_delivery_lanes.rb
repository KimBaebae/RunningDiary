# Exercise release lane arguments without Fastlane, credentials, network, or Apple writes.
require 'minitest/autorun'

module UI
  def self.user_error!(message)
    raise ArgumentError, message
  end
end

class LaneHarness
  attr_reader :uploads
  def initialize
    @lanes = {}
    @uploads = []
    instance_eval(File.read(File.expand_path('../fastlane/Fastfile', __dir__)))
  end
  def default_platform(*); end
  def platform(*); yield; end
  def desc(*); end
  def lane(name, &block); @lanes[name] = block; end
  def app_store_connect_api_key(**); :fake_api_key; end
  def upload_to_app_store(**options); @uploads << options; end
  def run(name); instance_exec(&@lanes.fetch(name)); end
  # Rebuilding, signing, or uploading a binary calls an undefined method and fails this harness.
end

class DeliveryLaneTests < Minitest::Test
  def setup
    @old = %w[RELEASE_APP_VERSION RELEASE_BUILD_NUMBER].to_h { |key| [key, ENV[key]] }
    ENV['RELEASE_APP_VERSION'] = '1.2.0'
    ENV['RELEASE_BUILD_NUMBER'] = '42'
  end
  def teardown
    @old.each { |key, value| ENV[key] = value }
  end
  def test_submits_only_the_named_existing_build_without_automatic_release
    runner = LaneHarness.new
    runner.run(:release)
    assert_equal 1, runner.uploads.size
    options = runner.uploads.first
    assert_equal '1.2.0', options[:app_version]
    assert_equal '42', options[:build_number]
    assert_equal true, options[:skip_binary_upload]
    assert_equal true, options[:submit_for_review]
    assert_equal false, options[:automatic_release]
  end
  def test_missing_build_stops_before_submission
    ENV.delete('RELEASE_BUILD_NUMBER')
    runner = LaneHarness.new
    assert_raises(KeyError) { runner.run(:release) }
    assert_empty runner.uploads
  end
  def test_invalid_version_stops_before_submission
    ENV['RELEASE_APP_VERSION'] = 'latest'
    runner = LaneHarness.new
    assert_raises(ArgumentError) { runner.run(:release) }
    assert_empty runner.uploads
  end
end
