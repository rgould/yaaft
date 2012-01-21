Feature: ReplayGain
  In order to make sure the music I hear is at reasonable levels
  As a music snob
  I want all of my mp3s to contain track and album replaygain data

  Scenario: Missing File
    When I run `yaaft replaygain missing-file`
    Then the output should contain "No such file or directory: missing-file"

  Scenario: Multiple Files
    When I run `yaaft replaygain low-cbr.mp3 low-vbr.mp3`

  Scenario: Folders
    When I run `yaaft replaygain subfolder`

  Scenario: File contains no replay gain info
    When I run `yaaft replaygain gain-no-info.mp3`
    Then the output should contain "gain-no-info... Adding tags"

  Scenario: File contains replay gain data in ID3v2 tags
    When I run `yaaft replaygain gain-in-id3.mp3`
    Then the output should contain "gain-in-id3.mp3... OK"

  Scenario: File contains replay gain data in APEv2
    When I run `yaaft replaygain gain-in-ape.mp3`
    Then the output should contain "gain-in-ape.mp3... Adding tags"

  Scenario: File contains only track level replay gain data
    When I run `yaaft replaygain gain-track-only.mp3`
    Then the output should contain "gain-track-only.mp3... Adding tags"
