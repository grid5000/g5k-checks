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

  it "should have postinstall version equals to version in reference api" do
    curPost = @g5k["postinstall"]["version"]
    refPost = RSpec.configuration.node.api_description["software"]["postinstall-version"]
    Utils.test(curPost, refPost, "Postinstall version", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end

  it "should have the forced deployment timestamp equals to the one in reference api" do
    curTs = @g5k["forced-deployment-timestamp"]
    refTs = RSpec.configuration.node.api_description["software"]["forced-deployment-timestamp"]
    Utils.test(curTs, refTs, "Forced deployment timestamp equality", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end
