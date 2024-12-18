require 'roo'

class ExcelLoader
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
  end

  def load_data
    mines = []
    sheet = Roo::Excelx.new(file_path)
    sheet.each_row_streaming(offset: 1) do |row|
      mines << { name: row[0].value.strip.downcase, owner: row[6]&.value&.strip&.downcase }
    end
    mines
  end
end
