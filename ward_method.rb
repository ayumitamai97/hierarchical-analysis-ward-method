# frozen_string_literal: true

require 'csv'
require 'logger'
require_relative 'calculation'

class WardMethod
  attr_reader :input_filename, :is_examination, :logger, :sample

  Cluster = Struct.new(:samples, :dissimilarity, keyword_init: true)
  ProvisionalCluster = Struct.new(:diff_between_sqds, :c1, :c2, keyword_init: true)

  def initialize(input_filename:)
    @input_filename = input_filename
    @is_examination = false
    @logger = Logger.new(STDOUT)
  end

  def examine_dissimilarity
    @is_examination = true
    multiple_analysis_results = multiple_analysis_with_dissimilarity
    multiple_analysis_results.each_with_object([]) do |(clusters_count, result), summary|
      summary << {
        clusters_count: clusters_count,
        dissimilarity: Math.log10(result[:dissimilarity])
      }
    end
  end

  def multiple_analysis_with_dissimilarity
    (1..15).each_with_object({}) do |count, results_of_analysis|
      logger.info("Starting with cluster_count: #{count}")
      clusters = execute(clusters_count: count)
      results_of_analysis[count] = {
        clusters: clusters,
        dissimilarity: clusters.max { |cl_1, cl_2| cl_1.dissimilarity <=> cl_2.dissimilarity }.dissimilarity
      }
    end
  end

  def execute(clusters_count:)
    # `1クラスタ∋1サンプル` から始める
    clusters = samples.map { |sample| Cluster.new(samples: [sample], dissimilarity: 0) }

    while clusters.count > clusters_count
      logger.info("Current number of clusters: #{clusters.count}")
      combinations = gen_combinations_from(clusters: clusters)
      new_cluster = gen_new_cluster_from(combinations: combinations)
      clusters = reunite_clusters(old_clusters: clusters, new_cluster: new_cluster)
    end

    save_results(clusters: clusters)
  end

  private

  def sample
    @sample ||= Struct.new('Sample', *all_member_names, keyword_init: true)
  end

  def member_variable_names
    # NOTICE: 分析対象のヘッダ列は1列目のみとする.
    all_member_names.drop(1)
  end

  def all_member_names
    CSV.open(input_filename, &:readline).map(&:to_sym)
  end

  def samples
    population = CSV.foreach(input_filename, headers: :first_line).with_object([]) do |row, samples|
      arguments_to_initialize_sample =
        all_member_names.each_with_object({}).with_index do |(member_name, arguments_to_initialize_sample), i|
          # NOTICE: 分析対象のヘッダ列は1列目のみとする.
          arguments_to_initialize_sample[member_name] = i > 0 ? row[i].to_i : row[i]
        end
      samples << sample.new(arguments_to_initialize_sample)
    end
    is_examination ? population.each_slice(5).map(&:first) : population # 系統抽出
  end

  # MEMO: 略語
  # cn: cluster n
  # cu: cluster united
  # cg: center of gravity
  # sqd: squared distance
  def gen_combinations_from(clusters:)
    provisional_clusters = []
    clusters.combination(2) do |c1, c2|
      cg_of_c1 = ::Calc.cg(sample: sample, array: c1.samples, name: 'C1の重心', member_variable_names: member_variable_names)
      cg_of_c2 = ::Calc.cg(sample: sample, array: c2.samples, name: 'C2の重心', member_variable_names: member_variable_names)

      cu_samples = c1.samples | c2.samples
      cg_of_cu = ::Calc.cg(sample: sample, array: cu_samples, name: 'C1とC2を連結した仮クラスターの重心', member_variable_names: member_variable_names)

      # ユークリッド距離
      sum_of_sqd_between_c1_cg_and_sample = ::Calc.sum_of_sqds(samples: c1.samples, center_of_g: cg_of_c1, member_variable_names: member_variable_names)
      sum_of_sqd_between_c2_cg_and_sample = ::Calc.sum_of_sqds(samples: c2.samples, center_of_g: cg_of_c2, member_variable_names: member_variable_names)
      sum_of_sqd_between_cu_cg_and_sample = ::Calc.sum_of_sqds(samples: cu_samples, center_of_g: cg_of_cu, member_variable_names: member_variable_names)

      provisional_clusters << ProvisionalCluster.new(
        diff_between_sqds: sum_of_sqd_between_cu_cg_and_sample - sum_of_sqd_between_c1_cg_and_sample - sum_of_sqd_between_c2_cg_and_sample,
        c1: c1, c2: c2
      )
    end
    provisional_clusters
  end

  def gen_new_cluster_from(combinations:)
    new_cluster_prov = combinations.min { |a, b| a.diff_between_sqds <=> b.diff_between_sqds }
    new_cluster = Cluster.new(samples: new_cluster_prov.c1.samples | new_cluster_prov.c2.samples, dissimilarity: new_cluster_prov.diff_between_sqds)
  end

  def reunite_clusters(old_clusters:, new_cluster:)
    old_clusters.delete_if { |cluster| (new_cluster.samples & cluster.samples).count > 0 } # 新しく作ったクラスタとサンプルを共有する古いクラスタを削除する意
    old_clusters.push new_cluster
  end

  def save_results(clusters:)
    now = Time.now.strftime('%Y%m%d%H%M')
    CSV.open("csv/ward_method_result_#{now}.csv", 'wb') do |csv|
      csv << %w[cluster_number sample_name].push(*member_variable_names)
      clusters.each_with_index do |cluster, i|
        cluster.samples.each do |sample|
          csv << [
            i + 1,
            sample.name,
            *member_variable_names.map { |mem| sample.public_send(mem) }
          ]
        end
      end
    end
  end
end
