Feature: Bitrate Analyser
  In order to cleanse my music collection of low-quality sounds
  As a music snob
  I want to be notified if any mp3s have a bitrate lower than 192 kbps

  Scenario: Missing File
    When I run "yaaft bitrate missing-file"
    Then the output should contain "No such file or directory: missing-file"

  Scenario: Low Constant Bit Rate
    When I run "yaaft bitrate low-cbr.mp3"
    Then the output should contain "low-cbr.mp3... low bitrate!"

  Scenario: High Constant Bit Rate
    When I run "yaaft bitrate high-cbr.mp3"
    Then the output should contain "high-cbr.mp3... OK"
