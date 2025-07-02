# frozen_string_literal: true

require_relative 'gemspy/version'

require 'optparse'
require 'csv'
require 'active_support'
require 'active_support/core_ext'

module Gemspy
  class Cli
    State = Struct.new(:gem_list_path, :apps_path, :output_csv, :apps, :gems, :scan, keyword_init: true) do
      def initialize(gem_list_path: nil, apps_path: nil, output_csv: nil, apps: [], gems: [], scan: {})
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
      output_xls
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
        parser.on('-o', '--output FILENAME.csv', 'Ouput CSV filename') { |o| @state.output_csv = o }
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
      error '-o is required' if @state.output_csv.nil?

      error "File '#{@state.gem_list_path}' isn't found" unless File.exist?(@state.gem_list_path)
      error "Directory '#{@state.apps_path}' isn't found" unless Dir.exist?(@state.apps_path)
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
      @state.apps.each do |app|
        lock = File.join(@state.apps_path, app, 'Gemfile.lock')
        next unless File.exist?(lock)

        File.open(lock).each_line do |line|
          @state.gems.each do |gem|
            version = fetch_version(line, gem)
            @state.scan[gem][app] = version if version
          end
        end
      end
    end

    def fetch_version(line, gem)
      escaped_gem = Regexp.escape(gem)
      match = line.strip.match(/^#{escaped_gem} \((\d+(?:\.\d+)*)\)$/)
      return unless match

      match[1]
    end

    def output_xls
      headers = [''] + @state.gems

      CSV.open(@state.output_csv, 'w', write_headers: true, headers:, col_sep: ';') do |csv|
        apps_with_versions.each do |app|
          line = [app]
          @state.gems.each do |gem|
            app_to_version = @state.scan[gem]
            version = app_to_version ? app_to_version[app] : nil
            line << version
          end
          csv << line
        end
      end
    end

    def apps_with_versions
      apps_with_versions = []
      @state.scan.each_value do |app_to_version|
        app_to_version.each do |app, version|
          apps_with_versions << app if version.present?
        end
      end
      apps_with_versions.uniq.sort
    end

    def error(msg)
      abort "Error: #{msg}"
    end
  end
end
