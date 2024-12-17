require 'mitie'
require 'roo'
require 'yaml'
require 'date'
require 'fuzzy_match'

EXCEL_FILE = File.expand_path("data/Gold Mines Dataset Subsample CONFIDENTIAL 23 02 2024.xlsx", __dir__)
# Класс для распознавания и классификации сущностей
class MineRecognizer
  attr_reader :mine_data, :metrics, :ticker_symbols, :ner

  def initialize(excel_file)
    @mine_data = load_excel_data(excel_file) # Данные о шахтах и компаниях
    @metrics = load_metrics                 # Ключевые метрики
    @ticker_symbols = load_ticker_symbols   # Тикеры акций
    @mine_keywords = load_mine_keywords # Ключевые слова для новых шахт
    @ner = Mitie::NER.new('/home/swiftx/Desktop/ZHAW/IREP/MITIE-models-v0.2/MITIE-models/english/ner_model.dat') # NER модель
  end

  # Метод очистки списков от дубликатов, схожих строк и лишних пробелов
  def clean_list(items)
    # Нормализация и удаление пустых строк
    cleaned = items
                .map { |item| item.strip.downcase.gsub(/\s+/, ' ').gsub(/[^a-z0-9\s]/, '') }
                .reject { |item| item.empty? || item.length < 3 }
                .uniq
  
    # Удаляем похожие строки
    fuzzy = FuzzyMatch.new(cleaned)
    unique_items = []
  
    cleaned.each do |item|
      # Проверяем, есть ли уже похожий элемент в списке уникальных
      unless unique_items.any? { |u| fuzzy.find(item) == u }
        unique_items << item
      end
    end
  
    unique_items.map(&:capitalize)
  end
  


  # Основной метод обработки текста новостей
  def process_news(file_path)
    news_text = File.read(file_path)
    location_extractor = LocationExtractor.new(EXCEL_FILE)
    known_locations = location_extractor.known_locations.map do |loc|
      [loc[:region], loc[:country], loc[:state]].compact.map(&:downcase)
    end.flatten.uniq
  
    # Шаг 1: Классификация шахт и компаний
    mines, companies = classify_mines_and_companies(news_text, known_locations)
  
    # Шаг 2: Извлечение метрик и тикеров
    metrics, tickers = extract_metrics_and_tickers(news_text)
  
    # Шаг 3: Извлечение дат, email и URL
    entities = extract_dates_and_links(news_text)
  
    # Шаг 4: Очистка и вывод результатов
    puts "Detected Mines:"
    puts "\nExisting Mines:" unless mines[:existing].empty?
    mines[:existing].each { |mine| puts "- #{mine}" }
    
    puts "\nPotential New Mines:" unless mines[:new].empty?
    mines[:new].each { |mine| puts "- #{mine}" }
  
    puts "\nDetected Companies:"
    companies.each { |company| puts "- #{company}" }
  
    puts "\nDetected Metrics:"
    metrics.each { |metric| puts "- #{metric}" }
  
    puts "\nDetected Ticker Symbols:"
    tickers.each { |ticker| puts "- #{ticker}" }
  
    puts "\nExtracted Datetimes:"
    entities[:datetime].each { |dt| puts "- #{dt} (DATETIME)" }
  
    puts "\nExtracted Emails:"
    entities[:emails].each { |email| puts "- #{email} (EMAIL)" }
  
    puts "\nExtracted URLs:"
    entities[:urls].each { |url| puts "- #{url} (URL)" }
  end
  
  

  private

  # Загрузка данных из Excel
  def load_excel_data(file_path)
    mines = []
    sheet = Roo::Excelx.new(file_path)
    sheet.each_row_streaming(offset: 1) do |row|
      mines << {
        name: row[0].value.strip.downcase, # PROP_NAME
        owner: row[6]&.value&.strip&.downcase # OWNER_NAME
      }
    end
    mines
  end

  # Загрузка метрик из файла YAML
  def load_metrics
    yaml_file = File.expand_path("data/metrics.yml", __dir__)
    metrics_data = YAML.load_file(yaml_file)
  
    # Объединяем все категории метрик в единый массив
    metrics_data.values.flatten
  end

  # Тикеры акций и индексов
  def load_ticker_symbols
    yaml_file = File.expand_path("data/ticker_symbols.yml", __dir__)
    ticker_data = YAML.load_file(yaml_file)
  
    ticker_data['ticker_symbols'] || []
  end

  # Метод загрузки ключевых слов из YAML
  def load_mine_keywords
    yaml_file = File.expand_path("data/mine_keywords.yml", __dir__)
    data = YAML.load_file(yaml_file)
    data['mine_keywords'] || []
  end

  def format_results(results)
    results.map { |result| result.split.map(&:capitalize).join(' ') }
  end

  # Классификация сущностей из текста
  
  def classify_mines_and_companies(text, known_locations)
    sentences = text.split(/(?<=\.)/)
    mines = { existing: [], new: [] }
    companies = []
  
    extra_words = %w[mine pit shaft quarry tunnel field resources inc et production reports record cost average doe nyse end]
    known_locations ||= []
  
    sentences.each do |sentence|
      tokens = Mitie::tokenize(sentence)
      entities = @ner.entities(tokens)
  
      entities.each do |entity|
        entity_text = tokens[entity[:token_index], entity[:token_length]].join(' ').strip.downcase
        normalized_text = entity_text.split.reject { |w| extra_words.include?(w) }.join(' ')
  
        # Проверка на существующие шахты
        existing_mine = @mine_data.find { |mine| fuzzy_match(mine[:name], normalized_text) }
        if existing_mine
          mines[:existing] << existing_mine[:name].capitalize
          next
        end
  
        # Исключаем известные локации
        next if known_locations.include?(normalized_text)
  
        # Проверка на компании
        existing_company = @mine_data.find { |mine| fuzzy_match(mine[:owner], normalized_text) }
        if existing_company
          companies << existing_company[:owner].capitalize
          next
        end
  
        # Проверка на новые шахты
        if @mine_keywords.any? { |kw| entity_text.include?(kw) }
          mines[:new] << entity_text.capitalize
        end
      end
    end
  
    # Очистка и нормализация
    mines[:existing].uniq!
    mines[:new] = clean_list(mines[:new]) - companies
    companies.uniq!
  
    [mines, companies]
  end
  
  def extract_metrics_and_tickers(text)
    sentences = text.split(/(?<=\.)/)
    metrics = []
    tickers = []
  
    sentences.each do |sentence|
      # Проверка на метрики
      metrics += @metrics.select { |metric| sentence.downcase.include?(metric.downcase) }
  
      # Проверка на тикеры
      tickers += @ticker_symbols.select { |ticker| sentence.upcase.include?(ticker) }
    end
  
    [metrics.uniq, tickers.uniq]
  end

  
  
  
  
  # Метод для извлечения дат, времени, email и URL из текста
  def extract_dates_and_links(text)
    entities = { datetime: [], emails: [], urls: [] }

    # Регулярные выражения для поиска
    datetime_regex = /(\w+\s\d{1,2},\s\d{4})\s?(\d{1,2}:\d{2}\s?(?:AM|PM|ET|GMT)?)/i
    date_regex = /(\b\w+\s\d{1,2},\s\d{4}\b)|(\b\d{4}-\d{2}-\d{2}\b)/
    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
    url_regex = /\b(?:https?:\/\/|www\.)[^\s]+/i

    # Извлечение сущностей
    text.scan(datetime_regex).each do |date, time|
      combined = "#{Date.parse(date).strftime('%Y-%m-%d')} #{time.strip}"
      entities[:datetime] << combined
    end

    # Добавляем даты без времени (если есть)
    text.scan(date_regex).flatten.compact.each do |date|
      formatted_date = Date.parse(date).strftime('%Y-%m-%d') rescue nil
      entities[:datetime] << formatted_date if formatted_date
    end

    entities[:datetime] = entities[:datetime].uniq.compact
    entities[:emails] = text.scan(email_regex).uniq
    entities[:urls] = text.scan(url_regex).uniq

    entities
  end

    # Метод для fuzzy-сравнения строк
  def fuzzy_match(name1, name2)
    return false if name1.nil? || name2.nil?
    FuzzyMatch.new([name1.downcase]).find(name2.downcase)
  end
end


class LocationExtractor
  attr_reader :known_locations

  def initialize(excel_file)
    @known_locations = load_known_locations(excel_file)
  end

  # Загрузка известных локаций из Excel
  def load_known_locations(excel_file)
    sheet = Roo::Spreadsheet.open(excel_file).sheet(0)
    locations = []

    sheet.each(SNL_GLOBAL_REGION: 'SNL_GLOBAL_REGION',
               COUNTRY_NAME: 'COUNTRY_NAME',
               STATE_PROVINCE: 'STATE_PROVINCE',
               LATITUDE: 'LATITUDE',
               LONGITUDE: 'LONGITUDE') do |row|
      next if row[:COUNTRY_NAME] == 'COUNTRY_NAME' # Пропускаем заголовок
      locations << {
        region: row[:SNL_GLOBAL_REGION],
        country: row[:COUNTRY_NAME],
        state: row[:STATE_PROVINCE],
        latitude: row[:LATITUDE],
        longitude: row[:LONGITUDE]
      }
    end
    locations
  end

  # Извлечение известных и неизвестных локаций
  def extract_locations(text)
    found_locations = text.scan(/\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)*\b/)
    known = found_locations & @known_locations.map { |loc| loc[:country] }
    unknown = found_locations - known
    { known: known.uniq, unknown: unknown.uniq }
  end

  # Извлечение GPS-координат из текста
  def extract_gps_coordinates(text)
    gps_regex = /-?\d{1,2}\.\d{5,},\s?-?\d{1,3}\.\d{5,}/
    text.scan(gps_regex).map do |coord|
      lat, lon = coord.split(',').map(&:to_f)
      { latitude: lat, longitude: lon }
    end.uniq
  end

  # Поиск ближайшей шахты к координатам
  def find_nearest_mine(gps_coordinates)
    gps_coordinates.map do |gps|
      nearest = @known_locations.min_by do |loc|
        haversine_distance(gps[:latitude], gps[:longitude], loc[:latitude], loc[:longitude])
      end
      { coordinates: gps, nearest_mine: nearest }
    end
  end

  private

  # Метод для вычисления расстояния между двумя точками (формула гаверсинуса)
  def haversine_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rkm = 6371 # Радиус Земли в км
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    lat1_rad, lat2_rad = lat1 * rad_per_deg, lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    rkm * c # Расстояние в километрах
  end
end



# --- Запуск программы ---
if __FILE__ == $0
  excel_file = 'data/Gold Mines Dataset Subsample CONFIDENTIAL 23 02 2024.xlsx'
  news_file = 'example_news.txt'

  recognizer = MineRecognizer.new(excel_file)
  recognizer.process_news(news_file)
end
