# Adapted from https://github.com/zspencer/make-many-rubies/blob/master/Makefile

# Allows running (and re-running) of tests against several ruby versions,
# assuming you use rbenv instead of rvm.

# Uses pattern rules (task-$:) and automatic variables ($*).
# Pattern rules: http://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_10.html#SEC98
# Automatic variables: http://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_10.html#SEC101

# Rbenv-friendly version identifiers for supported Rubys
24_version = 2.4.10
25_version = 2.5.8
26_version = 2.6.6
27_version = 2.7.1

# The ruby version for use in a given rule.
# Requires a matched pattern rule and a supported ruby version.
#
# Given a pattern rule defined as "install-ruby-%"
# When the rule is ran as "install-ruby-193"
# Then the inner addsuffix call evaluates to "193_version"
# And given_ruby_version becomes "1.9.3-p551"
given_ruby_version = $($(addsuffix _version, $*))

# Instruct rbenv on which Ruby version to use when running a command.
# Requires a pattern rule and a supported ruby version.
#
# Given a pattern rule defined as "test-%"
# When the rule is ran as "test-187"
# Then with_given_ruby becomes "RBENV_VERSION=1.8.7-p375"
with_given_ruby = RBENV_VERSION=$(given_ruby_version)


# Runs tests for all supported ruby versions.
test: test-24 test-25 test-26 test-27
test_24: test-24
test_25: test-25
test_26: test-26
test_27: test-27

# Runs tests against a specific ruby version
test-%:
	$(with_given_ruby) bundle install
	$(with_given_ruby) bundle exec rake