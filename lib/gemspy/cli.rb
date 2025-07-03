# frozen_string_literal: true

require 'optparse'

module Gemspy
  class Cli
    State = Struct.new(:gem_list_path, :apps_path, :output, :formatter, :apps, :gems, :scan, keyword_init: true) do
      def initialize(gem_list_path: nil, apps_path: nil, output: nil, formatter: nil, apps: [], gems: [], scan: {})
        super
      end
    end

    def initialize
      @state = State.new
    end

    def start
      parse_options
      validate_options
      read_options
      spy_gems
      Report.new(formatter: @state.formatter, output: @state.output, data: @state.scan).output
    end

    private

    def parse_options
      ARGV << '--help' if ARGV.empty?

      OptionParser.new do |parser|
        parser.banner = <<~BAN
          Usage: #{File.basename($PROGRAM_NAME)} [options]

        BAN

        parser.on('-g', '--gems FILE_PATH', 'Path to a list of gems to spy') { |g| @state.gem_list_path = g }
        parser.on('-a', '--apps DIRECTORY_PATH', 'Directory path with apps') { |a| @state.apps_path = a }
        parser.on('-o', '--output FILENAME', 'Output filename') { |o| @state.output = o }
        parser.on('-f', '--formatter FORMATTER', 'Formatter: csv or markdown') { |f| @state.formatter = f }
        parser.on_tail('-v', '--version', 'Show version') do
          puts VERSION
          exit
        end
        parser.on_tail('-h', '--help', 'Show help') do
          puts parser
          exit
        end
        parser.parse!
      end
    end

    def validate_options
      error '-g is required' if @state.gem_list_path.nil?
      error '-p is required' if @state.apps_path.nil?
      error '-o is required' if @state.output.nil?
      error '-f is required' if @state.formatter.nil?

      error "File '#{@state.gem_list_path}' isn't found" unless File.exist?(@state.gem_list_path)
      error "Directory '#{@state.apps_path}' isn't found" unless Dir.exist?(@state.apps_path)
      error "Formatter '#{@state.formatter}' is incorrect. Should be one of: #{FORMATTERS.join(', ')}" unless Report::FORMATTERS.include?(@state.formatter)
    end

    def read_options
      Dir.foreach(@state.apps_path) do |app|
        @state.apps << app unless app.start_with?('.')
      end

      File.read(@state.gem_list_path).split("\n").each do |gem|
        gem = gem.strip
        next if gem.blank?

        @state.gems << gem
      end

      @state.gems.each do |gem|
        @state.scan[gem] = {}
      end
    end

    def spy_gems
      gem_pattern = @state.gems.map { |gem| Regexp.escape(gem) }.join('|')
      pattern = /^(#{gem_pattern}) \((\d+(?:\.\d+)*)\)$/

      @state.apps.each do |app|
        next unless Dir.exist?(File.join(@state.apps_path, app, '.git'))

        lock = File.join(@state.apps_path, app, 'Gemfile.lock')
        next unless File.exist?(lock)

        File.open(lock).each_line do |line|
          stripped_line = line.strip
          match = stripped_line.match(pattern)
          next unless match

          gem_name, version = match.captures
          @state.scan[gem_name][app] = version
        end
      end
    end

    def error(msg)
      abort "Error: #{msg}"
    end
  end
end
