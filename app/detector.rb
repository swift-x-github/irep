require 'mitie'

# Шаг 1: Тренировка модели NER для распознавания сущностей
trainer = Mitie::NERTrainer.new("../MITIE-models-v0.2/MITIE-models/english/total_word_feature_extractor.dat")

# Пример текста для тренировки NER
tokens = ["Aguas", "Calientes", "is", "owned", "by", "Aldebaran", "Resources", "Inc", "and", "located", "in", "Argentina"]
instance = Mitie::NERTrainingInstance.new(tokens)
instance.add_entity(0..1, "mine")          # Aguas Calientes (шахта)
instance.add_entity(5..7, "owner")        # Aldebaran Resources Inc (владелец)
instance.add_entity(10..10, "country")    # Argentina (страна)

trainer.add(instance)

# Тренировка и сохранение модели NER
model = trainer.train
model.save_to_disk("ner_model.dat")
puts "NER model saved to 'ner_model.dat'"

# Шаг 2: Загрузка тренированного классификатора отношений
# Загрузка созданной модели
#ner_model = Mitie::NER.new("ner_model.dat")



detector = Mitie::BinaryRelationDetector.new("../MITIE-models-v0.2/MITIE-models/english/binary_relations/rel_classifier_organization.organization.place_founded.svm")

doc = model.doc("Shopify was founded in Ottawa")

detector.relations(doc)




# Шаг 3: Создание тренера для отношений
relation_trainer = Mitie::BinaryRelationTrainer.new(model)

# Пример текста и токенов
tokens = ["Aguas", "Calientes", "is", "located", "in", "Argentina", "and", "owned", "by", "Aldebaran", "Resources", "Inc"]

# Положительные примеры
relation_trainer.add_positive_binary_relation(tokens, 0..1, 5..5) # Aguas Calientes -> Argentina
relation_trainer.add_positive_binary_relation(tokens, 0..1, 9..11) # Aguas Calientes -> Aldebaran Resources Inc

# Отрицательные примеры
relation_trainer.add_negative_binary_relation(tokens, 10..10, 0..1) # Argentina -> Aguas Calientes (неправильно)
relation_trainer.add_negative_binary_relation(tokens, 9..11, 0..1) # Aldebaran Resources Inc -> Aguas Calientes (неправильно)

# Шаг 4: Тренировка и сохранение модели классификатора отношений
relation_detector = relation_trainer.train
relation_detector.save_to_disk("mine_relation_detector.svm")
puts "Binary relation detector saved to 'mine_relation_detector.svm'"

# Шаг 5: Тестирование на новом тексте
test_tokens = ["Aguas", "Calientes", "is", "located", "in", "Argentina", "and", "owned", "by", "Aldebaran", "Resources", "Inc"]

doc = model.doc(test_tokens.join(" "))
relations = relation_detector.relations(doc)

# Вывод найденных отношений
puts "\nDetected Relations:"
relations.each do |relation|
  puts "Relation: #{relation[:first]} -> #{relation[:second]} (Score: #{relation[:score]})"
end
