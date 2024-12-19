# require 'mitie'

# # Step 1: Train the NER model for entity recognition
# trainer = Mitie::NERTrainer.new("../MITIE-models-v0.2/MITIE-models/english/total_word_feature_extractor.dat")

# # Example text for NER training
# tokens = ["Aguas", "Calientes", "is", "owned", "by", "Aldebaran", "Resources", "Inc", "and", "located", "in", "Argentina"]
# instance = Mitie::NERTrainingInstance.new(tokens)
# instance.add_entity(0..1, "mine")          # Aguas Calientes (mine)
# instance.add_entity(5..7, "owner")        # Aldebaran Resources Inc (owner)
# instance.add_entity(11..11, "country")    # Argentina (country)

# trainer.add(instance)

# # Additional examples
# tokens2 = ["Aguas", "Calientes", "is", "operated", "by", "Aldebaran", "Resources", "Inc", "in", "Santa", "Cruz", "Argentina"]
# instance2 = Mitie::NERTrainingInstance.new(tokens2)
# instance2.add_entity(0..1, "mine")         # Canadon Langostura
# instance2.add_entity(5..7, "owner")       # Aldebaran Resources Inc
# instance2.add_entity(9..10, "location")   # Santa Cruz 

# trainer.add(instance2)

# # Train the NER model
# model = trainer.train
# model.save_to_disk("ner_model.dat")

# puts "NER model updated and saved to 'ner_model.dat'"

# # Step 2: Test the NER model
# doc = model.doc("Aguas Calientes is owned by Aldebaran Resources Inc and located in Argentina")
# entities = doc.entities
# puts "\nDetected Entities:"
# entities.each do |entity|
#   puts "Entity: #{entity[:text]}, Tag: #{entity[:tag]}, Score: #{entity[:score]}"
# end

# # Step 3: Create a trainer for binary relations
# relation_trainer = Mitie::BinaryRelationTrainer.new(model)

# # Example text and tokens
# relation_trainer.add_positive_binary_relation(tokens, 0..1, 5..7) # Aguas Calientes -> Aldebaran Resources Inc
# relation_trainer.add_positive_binary_relation(tokens, 0..1, 11..11) # Aguas Calientes  -> Argentina
# relation_trainer.add_positive_binary_relation(tokens, 5..7, 11..11) # Aldebaran Resources Inc -> Argentina

# relation_trainer.add_negative_binary_relation(tokens, 3..3, 11..11) # "is" is not related to Argentina
# relation_trainer.add_negative_binary_relation(tokens, 4..4, 11..11) # 
# relation_trainer.add_negative_binary_relation(tokens, 4..4, 10..10) # 

# relation_trainer.add_positive_binary_relation(tokens2, 0..1, 5..7) # Aguas Calientes -> Aldebaran Resources Inc
# relation_trainer.add_positive_binary_relation(tokens2, 0..1, 9..10) # Aguas Calientes -> Aldebaran Resources Inc


# # Step 4: Train and save the relation classifier
# relation_detector = relation_trainer.train
# relation_detector.save_to_disk("mine_relation_detector.svm")
# puts "Binary relation detector saved to 'mine_relation_detector.svm'"

# # Step 5: Test the relation classifier model
# test_tokens = ["Aguas", "Calientes", "is", "located", "in", "Argentina", "and", "owned", "by", "Aldebaran", "Resources", "Inc"]
# test_doc = model.doc(test_tokens.join(" "))

# # Extract relationships
# relations = relation_detector.relations(test_doc)

# # Output detected relationships
# puts "\nDetected Relations:"
# relations.each do |relation|
#   puts "Relation: #{relation[:first]} -> #{relation[:second]} (Score: #{relation[:score]})"
# end

require 'mitie'

# Step 1: Train the NER model for entity recognition
trainer = Mitie::NERTrainer.new("../MITIE-models-v0.2/MITIE-models/english/total_word_feature_extractor.dat")

# Example text for NER training
tokens = ["Aguas", "Calientes", "is", "owned", "by", "Aldebaran", "Resources", "Inc", "and", "located", "in", "Argentina"]
instance = Mitie::NERTrainingInstance.new(tokens)
instance.add_entity(0..1, "mine")          # Aguas Calientes (mine)
instance.add_entity(5..7, "owner")        # Aldebaran Resources Inc (owner)
instance.add_entity(11..11, "country")    # Argentina (country)

trainer.add(instance)

# Additional examples
tokens2 = ["Canadon", "Langostura", "is", "operated", "by", "E2", "Metals", "Limited", "in", "Santa", "Cruz", "Argentina"]
instance2 = Mitie::NERTrainingInstance.new(tokens2)
instance2.add_entity(0..1, "mine")         # Canadon Langostura
instance2.add_entity(5..7, "owner")       # E2 Metals Limited
instance2.add_entity(10..11, "country")   # Santa Cruz Argentina

trainer.add(instance2)

# Train the NER model
model = trainer.train
model.save_to_disk("ner_model.dat")

puts "NER model updated and saved to 'ner_model.dat'"

# Step 2: Test the NER model
doc = model.doc("Aguas Calientes is owned by Aldebaran Resources Inc and located in Argentina")
entities = doc.entities
puts "\nDetected Entities:"
entities.each do |entity|
  puts "Entity: #{entity[:text]}, Tag: #{entity[:tag]}, Score: #{entity[:score]}"
end

# Step 3: Create a trainer for binary relations
relation_trainer = Mitie::BinaryRelationTrainer.new(model)

# Example text and tokens
relation_trainer.add_positive_binary_relation(tokens, 0..1, 5..7) # Aguas Calientes -> Aldebaran Resources Inc
relation_trainer.add_positive_binary_relation(tokens2, 0..1, 5..7) # Canadon Langostura -> E2 Metals Limited

relation_trainer.add_negative_binary_relation(tokens, 3..3, 5..7) # "is" is not related to Aldebaran Resources Inc
relation_trainer.add_negative_binary_relation(tokens2, 4..4, 5..7) # "operated" is not related to E2 Metals Limited

# Step 4: Train and save the relation classifier
relation_detector = relation_trainer.train
relation_detector.save_to_disk("mine_relation_detector.svm")
puts "Binary relation detector saved to 'mine_relation_detector.svm'"

# Step 5: Test the relation classifier model
test_tokens = ["Aguas", "Calientes", "is", "owned", "by", "Aldebaran", "Resources", "Inc", "and", "located", "in", "Argentina"]
test_doc = model.doc(test_tokens.join(" "))

# Extract relationships
relations = relation_detector.relations(test_doc)

# Output detected relationships
puts "\nDetected Relations:"
relations.each do |relation|
  if relation[:first].include?("Aguas Calientes") || relation[:first].include?("Canadon Langostura")
    puts "Relation: #{relation[:first]} -> #{relation[:second]} (Score: #{relation[:score]})"
  end
end
