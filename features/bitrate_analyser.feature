Feature: Bitrate Analyser
  In order to cleanse my music collection of low-quality sounds
  As a music snob
  I want to be notified if any mp3s have a bitrate lower than 192 kbps

  Scenario: Missing File
    When I run `yaaft bitrate missing-file`
    Then the output should contain "No such file or directory: missing-file"

  Scenario: Multiple Files
    When I run `yaaft bitrate low-cbr.mp3 low-vbr.mp3`
    Then the output should contain "low-cbr.mp3... low bitrate: 128kbps"
    And the output should contain "low-vbr.mp3... low bitrate: 31kbps vbr"

  Scenario: Folders
    When I run `yaaft bitrate subfolder`
    Then the output should contain "subfolder/low-cbr.mp3... low bitrate: 128kbps"
    And the output should contain "subfolder/low-vbr.mp3... low bitrate: 31kbps vbr"

  Scenario: Low Constant Bit Rate
    When I run `yaaft bitrate low-cbr.mp3`
    Then the output should contain "low-cbr.mp3... low bitrate: 128kbps"
    And the output should not contain "vbr"

  Scenario: High Constant Bit Rate
    When I run `yaaft bitrate high-cbr.mp3`
    Then the output should contain "high-cbr.mp3... OK"

  Scenario: Low Variable Bit Rate
    When I run `yaaft bitrate low-vbr.mp3`
    Then the output should contain "low-vbr.mp3... low bitrate: 31kbps vbr"

  Scenario: High Variable Bit Rate
    When I run `yaaft bitrate high-vbr.mp3`
    Then the output should contain "high-vbr.mp3... OK"

