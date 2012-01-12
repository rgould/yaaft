# language: en-lol
OH HAI: Command Line Interface
  In order to not be hit in the face by someone wielding The Art of Unix Programming
  As a developer
  I will make this application have a sensible command line interface

  MISHUN: HJALP!
    WEN I run `yaaft --help`
    DEN the stdout should contain "Usage:"
    AN the stdout should contain "-v, --version"
    AN the stdout should contain "-h, --help"

  MISHUN: I CAN HAZ VERSION
    WEN I run `yaaft --version`
    DEN the stdout should contain exactly the yaaft version

  MISHUN: WHEN I SPEW GARBAGE I GETS HJALP!
    WEN I run `yaaft jfkldjfkljdklfjdlfjkdl`
    DEN the stdout should contain exactly:
      """
      Unknown subcommand. Try --help

      """
