# frozen_string_literal: true

class Calc
  class << self
    def sq(n)
      n * n
    end

    def avg(array)
      array.sum.to_f / array.count
    end

    def cg(sample:, array:, name:, member_variable_names:)
      cg = sample.new(name: name)
      member_variable_names.each_with_object(cg) do |variable_name|
        points = array.map(&variable_name)
        cg.send("#{variable_name}=", avg(points))
      end
    end

    def sum_of_sqds(samples:, center_of_g:, member_variable_names:)
      samples.inject(0) do |sum, sample|
        sum += sqds(points: [center_of_g, sample], member_variable_names: member_variable_names)
      end
    end

    # points: n次元グラフ上の2点
    # member_variable_names: 軸の名前
    def sqds(points:, member_variable_names:)
      member_variable_names.each_with_object([]) do |variable_name, diffs|
        coordinates = points.each_with_object([]) do |point, coordinates|
          coordinates << point.send(variable_name)
        end
        diffs << sq(coordinates[0] - coordinates[1])
      end.sum
    end
  end
end
