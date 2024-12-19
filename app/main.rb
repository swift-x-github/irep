require 'yaml'
require_relative 'services/mine_recognizer'
require_relative 'services/spacy_service'
def main
  # Загружаем конфигурацию
  config = YAML.load_file(File.expand_path('config.yaml', __dir__))
  news_file = config['news_file']

  recognizer = MineRecognizer.new(config)
  recognizer.process_news(news_file)
end

main
