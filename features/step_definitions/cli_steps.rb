Then /^the stdout should contain exactly the yaaft version$/ do
  assert_exact_output("#{Yaaft::VERSION}\n", all_stdout)
end
