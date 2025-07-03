# Gemspy

Gemspy is a command-line tool that scans multiple Ruby apps by reading their `Gemfile.lock` files. It checks which
versions of specific gems are used and outputs the results as a CSV or Markdown file.

1. Clone repositories
2. If it's a gem, `cd` into it and run `bundle`
3. `./exe/gemspy --gems example-gems --apps ~/projects/ -f csv -o example.csv`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
