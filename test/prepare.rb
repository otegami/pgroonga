#!/usr/bin/env ruby

require "find"
require "fileutils"
require "pathname"

def open_output(output_path)
  if output_path
    puts "DEBUG: Writing schedule to: #{output_path}"
    File.open(output_path, "w") do |output|
      yield(output)
    end
  else
    puts "DEBUG: Writing schedule to stdout"
    yield($stdout)
  end
end

open_output(ARGV[0]) do |output|
  source_dir = File.dirname(File.dirname(__FILE__))
  puts "DEBUG: Source directory: #{source_dir}"
  sql_dir_path = Pathname.new(File.join(source_dir, "sql"))
  puts "DEBUG: SQL directory: #{sql_dir_path}"
  puts "DEBUG: BUILD_DIR env: #{ENV['BUILD_DIR']}"

  test_count = 0
  Find.find(sql_dir_path) do |entry|
    entry_path = Pathname.new(entry)
    relative_path = entry_path.relative_path_from(sql_dir_path)

    if File.directory?(entry)
      results_directory = File.join("results", relative_path.to_s)
      build_dir = ENV["BUILD_DIR"]
      if build_dir
        results_directory = File.join(build_dir, results_directory)
      end
      puts "DEBUG: Creating directory: #{results_directory}"
      FileUtils.mkdir_p(results_directory)
    elsif File.file?(entry)
      next unless entry.end_with?(".sql")
      test_file = relative_path.sub_ext("")
      puts "DEBUG: Adding test: #{test_file}"
      output.puts("test: #{test_file}")
      test_count += 1
    end
  end
  puts "DEBUG: Total tests found: #{test_count}"
end
