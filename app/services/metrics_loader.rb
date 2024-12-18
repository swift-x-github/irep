require 'yaml'

class MetricsLoader
  def initialize(metrics_file)
    @metrics_file = metrics_file
  end

  def load_data
    YAML.load_file(@metrics_file).values.flatten
  end

  def load_keywords
    YAML.load_file(@metrics_file)['mine_keywords'] || []
  end
end
