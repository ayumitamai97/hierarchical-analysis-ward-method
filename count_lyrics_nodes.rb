# frozen_string_literal: true

require 'csv'

class CountLyricsNodes
  def initialize(input_filename:, output_filename:)
    @input_filename = input_filename
    @output_filename = output_filename
  end

  attr_reader :input_filename, :output_filename

  def execute
    all_nodes = songs.map { |s| s[:nodes] }.flatten.uniq
    CSV.open(output_filename, 'wb') do |csv|
      csv << ['name', *all_nodes]
      songs.each do |song|
        csv << [
          song[:songname], # Expecting songname to be unique
          *all_nodes.map { |node| song[:nodes].count(node) }
        ]
      end
    end
  end

  private

  def songs
    CSV.foreach(input_filename, headers: false).with_object([]) do |row, songs|
      songs << {
        musician: row[0],
        songname: row[1],
        nodes: row[2..-1]
      }
    end
  end
end
