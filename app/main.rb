require 'yaml'
require_relative 'services/mine_recognizer'

def main
  # Загружаем конфигурацию
  config = YAML.load_file(File.expand_path('config.yaml', __dir__))
  puts "Loaded config: #{config.inspect}" # Отладка

  excel_file = config['excel_file']
  news_file = config['news_file']

  puts "Excel File: #{excel_file}" # Отладка
  puts "News File: #{news_file}"   # Отладка

  recognizer = MineRecognizer.new(config)
  recognizer.process_news(news_file)
end

main
