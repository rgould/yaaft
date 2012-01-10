require 'aruba/cucumber'

Before do
  FileUtils.cp_r 'testdata', 'tmp/aruba'
end
