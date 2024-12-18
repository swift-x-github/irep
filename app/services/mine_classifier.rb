require 'fuzzy_match'

class MineClassifier
  def initialize(mine_data, mine_keywords, ner, known_locations)
    @mine_data = mine_data
    @mine_keywords = mine_keywords
    @ner = ner
    @known_locations = known_locations
  end

  def classify(text)
    sentences = text.split(/(?<=\.)/)
    mines = { existing: [], new: [] }
    companies = []

    sentences.each do |sentence|
      tokens = Mitie::tokenize(sentence)
      entities = @ner.entities(tokens)

      entities.each do |entity|
        entity_text = tokens[entity[:token_index], entity[:token_length]].join(' ').strip.downcase
        classify_entity(entity_text, mines, companies)
      end
    end

    [mines, companies]
  end

  private

  def classify_entity(entity_text, mines, companies)
    normalized_text = entity_text.gsub(/[^a-z0-9\s]/, '').strip.downcase
    existing_mine = @mine_data.find { |mine| fuzzy_match(mine[:name], normalized_text) }

    if existing_mine
      mines[:existing] << existing_mine[:name].capitalize
    elsif @mine_keywords.any? { |kw| entity_text.include?(kw) }
      mines[:new] << entity_text.capitalize
    elsif @mine_data.find { |mine| fuzzy_match(mine[:owner], normalized_text) }
      companies << entity_text.capitalize
    end
  end

  def fuzzy_match(name1, name2)
    FuzzyMatch.new([name1]).find(name2)
  end
end
