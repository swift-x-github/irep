require 'mitie'
require_relative 'excel_loader'
require_relative 'metrics_loader'
require_relative 'ticker_loader'
require_relative 'mine_classifier'
require_relative 'entity_extractor'
require_relative 'result_printer'
require_relative 'location_extractor'
require_relative 'mitie_service'
require_relative 'spacy_service'

# class MineRecognizer
#   def initialize(config)
#     @excel_loader = ExcelLoader.new(config['excel_file'])
#     @metrics_loader = MetricsLoader.new(config['metrics_file'])
#     @ticker_loader = TickerLoader.new(config['ticker_symbols_file'])
#     @ner = Mitie::NER.new(config['ner_model_path'])

#     @mine_data = @excel_loader.load_data
#     @metrics = @metrics_loader.load_data
#     @ticker_symbols = @ticker_loader.load_data
#     @mine_keywords = @metrics_loader.load_keywords
#   end

#   def process_news(file_path)
#     news_text = File.read(file_path)
#     location_extractor = LocationExtractor.new(@excel_loader.file_path)
#     known_locations = location_extractor.known_locations.map do |loc|
#       [loc[:region], loc[:country], loc[:state]].compact.map(&:downcase)
#     end.flatten.uniq

#     mines, companies = MineClassifier.new(@mine_data, @mine_keywords, @ner, known_locations).classify(news_text)
#     metrics, tickers = EntityExtractor.new(@metrics, @ticker_symbols).extract_metrics_and_tickers(news_text)
#     entities = EntityExtractor.new(@metrics, @ticker_symbols).extract_dates_and_links(news_text)

#     ResultPrinter.new.print_results(mines, companies, metrics, tickers, entities)
#   end
# end
class MineRecognizer
  def initialize(config)
    @excel_loader = ExcelLoader.new(config['excel_file'])
    @metrics_loader = MetricsLoader.new(config['metrics_file'])
    @ticker_loader = TickerLoader.new(config['ticker_symbols_file'])

    @mine_data = @excel_loader.load_data #; p @mine_data
    @metrics = @metrics_loader.load_data
    @ticker_symbols = @ticker_loader.load_data
    @mine_keywords = @metrics_loader.load_keywords

    # Выбор модели на основе конфигурации
    @entity_service = if config['model'] == 'mitie'
                        MitieService.new(config['ner_model_path'])
                      elsif config['model'] == 'spacy'
                        SpacyService.new(1.py)
                      else
                        raise "Unsupported model: #{config['model']}"
                      end
  end

  def process_news(file_path)
    news_text = File.read(file_path)
    location_extractor = LocationExtractor.new(@excel_loader.file_path)
    known_locations = location_extractor.known_locations.map do |loc|
      [loc[:region], loc[:country], loc[:state]].compact.map(&:downcase)
    end.flatten.uniq

    # Извлекаем сущности с помощью выбранного сервиса
    entities = @entity_service.extract_entities(news_text)
    mines, companies, locations, persons  = classify_mines_and_companies(entities, known_locations)
    metrics, tickers = EntityExtractor.new(@metrics, @ticker_symbols).extract_metrics_and_tickers(news_text)
    date_and_links = EntityExtractor.new(@metrics, @ticker_symbols).extract_dates_and_links(news_text)

    ResultPrinter.new.print_results(mines, companies, metrics, tickers, date_and_links, locations, persons)
  end

  private

  def classify_mines_and_companies(entities, known_locations)
    mines = { existing: [], new: [] }
    companies = []
    locations = []
    persons = []
    #p entities
    entities.each do |entity|
      normalized_text = entity[:text].downcase.strip
      normalized_text = entity[:text].strip

      known_locations.map!(&:downcase).map!(&:strip)
      next if known_locations.include?(normalized_text)

      case entity[:tag]
      when "ORGANIZATION"
        # Проверяем, является ли организация владельцем шахты
        if @mine_data.find { |mine| fuzzy_match(mine[:owner], normalized_text) }
          companies << entity[:text].capitalize
        end
      when "LOCATION"
        # Добавляем локации, если они не в известных
        locations << entity[:text].capitalize #unless known_locations.include?(normalized_text)
      when "PERSON"
        # Добавляем person если они не в известных
        persons << entity[:text].capitalize #unless known_locations.include?(normalized_text)
        # Если персона совпадает с известной шахтой, добавляем её в шахты
        existing_mine = @mine_data.find { |mine| mine[:name].casecmp(entity[:text].strip).zero? }
        if existing_mine
          mines[:existing] << existing_mine[:name].capitalize
        end
      else
        # Проверяем шахты
        # Проверка новых шахт
        if @mine_keywords.any? { |kw| normalized_text.include?(kw) }
          mines[:new] << entity[:text].capitalize
        end
      end
    end

    
    companies.uniq!
    locations.uniq!
    mines[:existing] = mines[:existing].uniq
    mines[:new] = mines[:new].uniq

    [mines, companies, locations, persons]
  end



  def fuzzy_match(name1, name2)
    return false if name1.nil? || name2.nil?
    FuzzyMatch.new([name1.downcase]).find(name2.downcase)
  end
end
