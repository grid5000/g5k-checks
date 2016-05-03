require 'restclient'
require 'json'

describe "Standard Environment Version" do

  before(:all) do
    site = %x(hostname).split('.')[1]
    @json = JSON.parse(RestClient.get("https://api.grid5000.fr/stable/sites/#{site}/internal/kadeployapi/environments?last=true&user=deploy&name=jessie-x64-std"))
    @curStd, @curPost = nil;
    File.open("/etc/grid5000/release", "r") do |infile|
      @curStd = infile.gets.strip
      @curPost = infile.gets.strip
    end
  end

  it "should have environment version equals to standard env in kadeploy api" do
    lastV = @json[0]["version"]
    lastN = @json[0]["name"]
    lastStd = "#{lastN}-#{lastV}"
    @curStd.should eql(lastStd), "Standard Environment Version is #{@curStd} instead of #{lastStd}"

  end

  it "should have postinstall version equals to version in kadeploy api" do
    lastPost = @json[0]["postinstalls"][0]["archive"]
    @curPost.should eql(lastPost), "Postinstalls Version is #{@curPost} instead of #{lastPost}"
  end

end
