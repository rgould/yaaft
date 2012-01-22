require "yaaft"

describe Yaaft::ReplayGainHelper, "has_tags?" do
  context "when the file has no replaygain data" do
    # this is the same case as having the replay gain data in the APE tags
    it "should apply replaygain data" do
      mp3info = replaygain
      Yaaft::ReplayGainHelper.has_tags?(mp3info).should be false
    end
  end

  context "when the file has replaygain data in ID3 tags" do
    it "has_tags should be false" do
      mp3info = replaygain(["trackfoo", "albumfoo"])
      Yaaft::ReplayGainHelper.has_tags?(mp3info).should be true
    end
  end

  context "when the file only has track gain data" do
    it "should apply replaygain data" do
      mp3info = replaygain("track")
      Yaaft::ReplayGainHelper.has_tags?(mp3info).should be false
    end
  end
end

def replaygain(rva2 = nil)
  rg = double
  tag2 = double
  rg.stub(:tag2).and_return(tag2)
  tag2.stub(:RVA2).and_return(rva2)

  rg
end
