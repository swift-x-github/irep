class ResultPrinter
    def print_results(mines, companies, metrics, tickers, entities)
      puts "Detected Mines:\n\nExisting Mines:" unless mines[:existing].empty?
      mines[:existing].each { |mine| puts "- #{mine}" }
  
      puts "\nPotential New Mines:" unless mines[:new].empty?
      mines[:new].each { |mine| puts "- #{mine}" }
  
      puts "\nDetected Companies:" unless companies.empty?
      companies.each { |company| puts "- #{company}" }
  
      puts "\nDetected Metrics:" unless metrics.empty?
      metrics.each { |metric| puts "- #{metric}" }
  
      puts "\nDetected Ticker Symbols:" unless tickers.empty?
      tickers.each { |ticker| puts "- #{ticker}" }
  
      puts "\nExtracted Datetimes:" unless entities[:datetime].empty?
      entities[:datetime].each { |dt| puts "- #{dt}" }
  
      puts "\nExtracted Emails:" unless entities[:emails].empty?
      entities[:emails].each { |email| puts "- #{email}" }
  
      puts "\nExtracted URLs:" unless entities[:urls].empty?
      entities[:urls].each { |url| puts "- #{url}" }
    end
  end
  