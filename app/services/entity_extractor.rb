class EntityExtractor
  def initialize(metrics, ticker_symbols)
    @metrics = metrics
    @ticker_symbols = ticker_symbols
  end

  def extract_metrics_and_tickers(text)
    metrics = @metrics.select { |metric| text.downcase.include?(metric.downcase) }
    tickers = @ticker_symbols.select { |ticker| text.upcase.include?(ticker) }
    [metrics.uniq, tickers.uniq]
  end

  # def extract_metrics_and_tickers(text)
  #   metrics = @metrics.select { |metric| text.downcase.include?(metric.downcase) }
  #   tickers = @ticker_symbols.select { |ticker| text.upcase.include?(ticker) && ticker.match?(/^\w{1,4}$/) }
  #   [metrics.uniq, tickers.uniq]
  # end

  
  def extract_dates_and_links(text)
    datetime_regex = /(\w+\s\d{1,2},\s\d{4})\s?(\d{1,2}:\d{2}\s?(?:AM|PM|ET|GMT)?)/i
    date_regex = /(\b\w+\s\d{1,2},\s\d{4}\b)|(\b\d{4}-\d{2}-\d{2}\b)/
    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
    url_regex = /\b(?:https?:\/\/|www\.)[^\s]+/i

    entities = { datetime: [], emails: text.scan(email_regex).uniq, urls: text.scan(url_regex).uniq }
    text.scan(datetime_regex).each { |date, time| entities[:datetime] << "#{Date.parse(date)} #{time.strip}" }
    text.scan(date_regex).each { |date| entities[:datetime] << Date.parse(date).to_s rescue nil }
    entities[:datetime].uniq!
    entities
  end
end
  