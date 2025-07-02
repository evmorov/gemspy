# frozen_string_literal: true

require_relative 'gemspy/version'

require 'optparse'
require 'active_support'
require 'active_support/core_ext'

module Gemspy
  class Cli
    State = Struct.new(:gem_list_path, :apps_path, :gems, :app_dirs, keyword_init: true) do
      def initialize(gem_list_path: nil, apps_path: nil, gems: [], app_dirs: [])
        super
      end
    end

    def initialize
      @state = State.new
      @state.gems = []
      @state.app_dirs = []
    end

    def start
      parse_options
      validate_options
      spy_gems
      puts @state
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

      error "File '#{@state.gem_list_path}' isn't found" unless File.exist?(@state.gem_list_path)
      error "Directory '#{@state.apps_path}' isn't found" unless Dir.exist?(@state.apps_path)
    end

    def spy_gems
      @app_dirs = []

      Dir.foreach(@state.apps_path) do |app_dir|
        next if app_dir.start_with?('.')

        @state.app_dirs << app_dir
      end

      File.read(@state.gem_list_path).split("\n").each do |gem|
        gem = gem.strip
        next if gem.blank?

        @state.gems << gem
      end
    end

    def error(msg)
      abort "Error: #{msg}"
    end
  end
end
