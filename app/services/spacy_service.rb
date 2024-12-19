require 'pycall/import'

# class SpacyService
#   include PyCall::Import

#   def initialize
#     # Импортируем Spacy через PyCall
#     pyimport 'spacy'
#     begin
#       @nlp = spacy.load('en_core_web_sm') # Загружаем модель Spacy
#     rescue StandardError => e
#       raise "Error loading Spacy model: #{e.message}. Make sure 'en_core_web_sm' is installed."
#     end
#   end

#   def extract_entities(text)
#     # Обрабатываем текст через Spacy
#     begin
#       doc = @nlp[text] # Используем квадратные скобки вместо call
#       entities = []

#       # Извлекаем сущности
#       doc.ents.each do |ent|
#         entities << { text: ent.text.to_s, tag: ent.label_.to_s }
#       end

#       entities
#     rescue StandardError => e
#       raise "Error processing text with Spacy: #{e.message}"
#     end
#   end
# end

# require 'ruby-spacy'

# class SpacyService
#   def initialize
#     @nlp = Spacy::Language.new('en_core_web_sm')
#   end

#   def extract_entities(text)
#     doc = @nlp.read(text)
#     doc.ents.map do |ent|
#       {
#         text: ent.text,
#         tag: ent.label_
#       }
#     end
#   end
# end
require 'open3'
require 'json'

class SpacyService
  def initialize(python_script_path)
    @python_script_path = python_script_path
  end

  def extract_entities(text)
    command = "python3 #{@python_script_path} \"#{text}\""
    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      JSON.parse(stdout) # Возвращаем распознанные сущности как массив хэшей
    else
      raise "Python script failed: #{stderr}"
    end
  end
end