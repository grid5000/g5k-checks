# coding: utf-8
require 'json'

describe "Standard Environment Version" do

  before(:all) do
    @g5k = RSpec.configuration.node.ohai_description["g5k"]
  end

  # user_deployed is true = job of type deploy
  # we don't verify the environment version
  it "should have environment version equals to standard env in kadeploy api" do
    if @g5k["user_deployed"]
      skip
    else
      lastV = @g5k["kadeploy"]["stdenv"]["version"]
      lastN = @g5k["kadeploy"]["stdenv"]["name"]
      lastStd = "#{lastN}-#{lastV}"
      stdNameVersion = @g5k["env"]["name"]
      Utils.test(stdNameVersion, lastStd, "Standard Environment Version", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end
  end

  it "should have postinstall version equals to version in kadeploy api" do
    curPost = @g5k["env"]["postinstalls"]
    lastPost = @g5k["kadeploy"]["stdenv"]["postinstalls"][0]["archive"]
    Utils.test(curPost, lastPost, "Environment post-installs version", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end

end
