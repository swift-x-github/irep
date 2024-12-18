require 'yaml'

class TickerLoader
  def initialize(ticker_symbols_file)
    @ticker_symbols_file = ticker_symbols_file
  end

  def load_data
    YAML.load_file(@ticker_symbols_file)['ticker_symbols'] || []
  end
end
