# frozen_string_literal: true

require_relative 'crawl_lyrics'
require_relative 'convert_lyrics_to_nodes'
require_relative 'count_lyrics_nodes'
require_relative 'ward_method'

URLS_CSV = 'csv/heisei_urls.csv'
LYRICS_LIST_CSV = 'csv/heisei_lyrics_list.csv'
LYRICS_NODES_CSV = 'csv/heisei_lyrics_nodes.csv'
SONGS_WITH_NODES_COUNT_CSV = 'csv/heisei_songs_with_nodes_count.csv'

CrawlLyrics.new(input_filename: URLS_CSV, output_filename: LYRICS_LIST_CSV).execute
ConvertLyricsToNodes.new(input_filename: LYRICS_LIST_CSV, output_filename: LYRICS_NODES_CSV).execute
CountLyricsNodes.new(input_filename: LYRICS_NODES_CSV, output_filename: SONGS_WITH_NODES_COUNT_CSV).execute
WardMethod.new(input_filename: SONGS_WITH_NODES_COUNT_CSV).examine_dissimilarity # => 7
WardMethod.new(input_filename: SONGS_WITH_NODES_COUNT_CSV).execute(clusters_count: 7)
