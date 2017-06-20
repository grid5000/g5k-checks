# coding: utf-8
require 'restclient'
require 'json'

describe "Standard Environment Version" do

  before(:all) do
    @g5k = RSpec.configuration.node.ohai_description["g5k"]
  end

  it "should have environment version equals to standard env in kadeploy api" do
    lastV = @g5k["kadeploy"]["stdenv"]["version"] rescue ""
    lastN = @g5k["kadeploy"]["stdenv"]["name"] rescue ""
    lastStd = "#{lastN}-#{lastV}"
    stdNameVersion = @g5k["env"]["name"] rescue ""
    Utils.test(stdNameVersion, lastStd, "Standard Environment Version", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end

  it "should have postinstall version equals to version in kadeploy api" do
    curPost = @g5k["env"]["postinstalls"] rescue ""
    lastPost = @g5k["kadeploy"]["stdenv"]["postinstalls"][0]["archive"] rescue ""
    Utils.test(curPost, lastPost, "Environment post-installs version", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end

end
