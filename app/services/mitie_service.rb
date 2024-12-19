class MitieService
  def initialize(ner_model_path)
    @ner = Mitie::NER.new(ner_model_path)
  end

  def extract_entities(text)
    tokens = Mitie::tokenize(text)
    entities = @ner.entities(tokens).map do |entity|
      entity_text = tokens[entity[:token_index], entity[:token_length]].join(' ')
      { text: entity_text, tag: entity[:tag] }
    end
    entities

  end
end
  