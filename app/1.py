import spacy
import json
import sys

def main():
    nlp = spacy.load("en_core_web_sm")
    input_text = sys.argv[1]
    doc = nlp(input_text)

    entities = [{"text": ent.text, "label": ent.label_} for ent in doc.ents]
    print(json.dumps(entities))  # Выводим сущности в формате JSON

if __name__ == "__main__":
    main()