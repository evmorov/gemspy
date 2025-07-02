# Gemspy

Gemspy is a command-line tool that scans multiple Ruby apps and checks which versions of specific gems they are using.
It outputs the results to a CSV file.

1. Clone repositories
2. If it's a gem, `cd` into it and run `bundle`
3. `./exe/gemspy --gems example-gems --apps ~/projects/ -o example.csv` 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
