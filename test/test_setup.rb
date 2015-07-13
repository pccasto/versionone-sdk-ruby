require 'test/unit'
require 'versionone_sdk'

class VersiononeSdkTest < Test::Unit::TestCase
  def testSetup

    oAsset  = VersiononeSdk::Asset.new
    oClient = VersiononeSdk::Client.new
    oParser = VersiononeSdk::ParserXmlAssets.new

    assert_equal 'VersiononeSdk::Asset', oAsset.class.name
    assert_equal 'VersiononeSdk::Client', oClient.class.name
    assert_equal 'VersiononeSdk::ParserXmlAssets', oParser.class.name

  end
end