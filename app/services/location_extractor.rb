class LocationExtractor
  attr_reader :known_locations

  def initialize(excel_file)
      @known_locations = load_known_locations(excel_file)
  end

  def load_known_locations(excel_file)
      sheet = Roo::Spreadsheet.open(excel_file).sheet(0)
      locations = []

      sheet.each(SNL_GLOBAL_REGION: 'SNL_GLOBAL_REGION',
                  COUNTRY_NAME: 'COUNTRY_NAME',
                  STATE_PROVINCE: 'STATE_PROVINCE') do |row|
      next if row[:COUNTRY_NAME] == 'COUNTRY_NAME' # Пропускаем заголовок
      locations << {
          region: row[:SNL_GLOBAL_REGION],
          country: row[:COUNTRY_NAME],
          state: row[:STATE_PROVINCE]
      }
      end
      locations
  end
end
  