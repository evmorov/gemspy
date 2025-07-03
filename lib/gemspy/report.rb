# frozen_string_literal: true

require 'csv'

module Gemspy
  class Report
    FORMATTERS = %w[csv markdown].freeze

    def initialize(formatter:, output:, data:)
      raise 'Wrong formatter' unless FORMATTERS.include?(formatter)

      @formatter = formatter
      @output = output
      @data = data
      @gems = data.keys
    end

    def output
      if @formatter == 'csv'
        output_csv
      else
        output_markdown
      end
    end

    private

    def output_csv
      headers = [''] + @gems

      CSV.open(@output, 'w', write_headers: true, headers:, col_sep: ';') do |csv|
        apps_with_versions.each do |app|
          line = [app]
          @gems.each do |gem|
            app_to_version = @data[gem]
            version = app_to_version ? app_to_version[app] : nil
            line << version
          end
          csv << line
        end
      end
    end

    def output_markdown
      headers = [''] + @gems

      all_rows = [headers]

      apps_with_versions.each do |app|
        row = [app]
        @gems.each do |gem|
          app_to_version = @data[gem]
          version = app_to_version ? app_to_version[app] : ''
          row << version
        end
        all_rows << row
      end

      col_widths = []
      all_rows.each do |row|
        row.each_with_index do |cell, i|
          col_widths[i] = [col_widths[i] || 0, cell.to_s.length].max
        end
      end

      File.open(@output, 'w') do |f|
        header_line = '|'
        headers.each_with_index do |header, i|
          header_line += " #{header.ljust(col_widths[i])} |"
        end
        f.puts header_line

        separator_line = '|'
        col_widths.each do |width|
          separator_line += "-#{'-' * width}-|"
        end
        f.puts separator_line

        apps_with_versions.each do |app|
          row_line = '|'
          row_line += " #{app.ljust(col_widths[0])} |"

          @gems.each_with_index do |gem, i|
            app_to_version = @data[gem]
            version = app_to_version ? app_to_version[app] : ''
            row_line += " #{version.to_s.ljust(col_widths[i + 1])} |"
          end

          f.puts row_line
        end
      end
    end

    def apps_with_versions
      apps_with_versions = []
      @data.each_value do |app_to_version|
        app_to_version.each do |app, version|
          apps_with_versions << app if version.present?
        end
      end
      apps_with_versions.uniq.sort
    end
  end
end
