# frozen_string_literal: true

require 'csv'
require_relative 'morph_analysis'

class ConvertLyricsToNodes
  def initialize(input_filename:, output_filename:)
    @input_filename = input_filename
    @output_filename = output_filename
  end

  attr_reader :input_filename, :output_filename

  def execute
    CSV.open(output_filename, 'wb') do |csv|
      songs.each do |song|
        csv << [
          song[:musician],
          song[:songname],
          *MorphAnalysis.new(text: song[:lyrics]).execute
        ]
      end
    end
  end

  private

  def songs
    CSV.foreach(input_filename, headers: :first_line).with_object([]) do |row, songs|
      songs << {
        musician: row['musician'],
        songname: row['songname'],
        lyrics: row['lyrics']
      }
    end
  end
end
