require 'aruba/cucumber'

Before do
  FileUtils.cp_r 'testdata', 'tmp/aruba'
  FileUtils.mkdir 'tmp/aruba/subfolder' unless FileTest.exist? 'tmp/aruba/subfolder'
  FileUtils.cp "testdata/low-cbr.mp3", "tmp/aruba/subfolder/low-cbr.mp3"
  FileUtils.cp "testdata/low-vbr.mp3", "tmp/aruba/subfolder/low-vbr.mp3"
end
