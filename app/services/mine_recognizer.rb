require 'mitie'
require_relative 'excel_loader'
require_relative 'metrics_loader'
require_relative 'ticker_loader'
require_relative 'mine_classifier'
require_relative 'entity_extractor'
require_relative 'result_printer'
require_relative 'location_extractor'


class MineRecognizer
  def initialize(config)
    @excel_loader = ExcelLoader.new(config['excel_file'])
    @metrics_loader = MetricsLoader.new(config['metrics_file'])
    @ticker_loader = TickerLoader.new(config['ticker_symbols_file'])
    @ner = Mitie::NER.new(config['ner_model_path'])

    @mine_data = @excel_loader.load_data
    @metrics = @metrics_loader.load_data
    @ticker_symbols = @ticker_loader.load_data
    @mine_keywords = @metrics_loader.load_keywords
  end

  def process_news(file_path)
    news_text = File.read(file_path)
    location_extractor = LocationExtractor.new(@excel_loader.file_path)
    known_locations = location_extractor.known_locations.map do |loc|
      [loc[:region], loc[:country], loc[:state]].compact.map(&:downcase)
    end.flatten.uniq

    mines, companies = MineClassifier.new(@mine_data, @mine_keywords, @ner, known_locations).classify(news_text)
    metrics, tickers = EntityExtractor.new(@metrics, @ticker_symbols).extract_metrics_and_tickers(news_text)
    entities = EntityExtractor.new(@metrics, @ticker_symbols).extract_dates_and_links(news_text)

    ResultPrinter.new.print_results(mines, companies, metrics, tickers, entities)
  end
end
