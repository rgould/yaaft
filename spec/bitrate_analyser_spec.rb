require "yaaft"

describe Yaaft::BitrateAnalyser do
  context "with a file that has a high constant bitrate" do
    it "should return true" do
      Yaaft::BitrateAnalyser.analyse(bitrate(192)).should == true
    end
  end

  context "with a file that has a low constant bitrate" do
    it "should return false" do
      Yaaft::BitrateAnalyser.analyse(bitrate(191)).should == false
    end
  end
end

def bitrate(rate)
  mp3info = double
  mp3info.stub(:bitrate) { rate }
  mp3info
end
