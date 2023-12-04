import os
import time
import json
import genanki
from local_translate import Translator


my_model = genanki.Model(
  1607392319,
  'words set 1',
  fields=[
    {'name': 'Word'},
    {'name': 'definitions'},
    {'name': 'synonyms'},
    {'name': 'persian'},
  ],
  templates=[
    {
      'name': 'Card 1',
      'qfmt': '<h1 style="color:blue"><center>{{Word}}</center></h1>',
      'afmt': '{{FrontSide}}<hr id="definitions"><h2 style="color:green">{{definitions}}</h2><hr id="synonyms"><h3 style="color:red"><center>{{persian}}</center></h3><br><br><hr id="synonyms">{{synonyms}}',
    },
  ])

def definition(word):
    rv = Translator(word).translate()
    return rv

def audio(word):
    url = f'https://translate.google.com/translate_tts?ie=UTF-8&q={word}&tl=en&total=1&idx=0&textlen=10&tk=823042.658175&client=t&prev=input'
    pass


def deck():
    return genanki.Deck(
        2059400110,
        'words set 1')

def translate_content(word):
    detail = definition(word)
    definitions = '<br/>---<br/>'.join(detail['definitions'])
    try:
      persian = detail['persian'][::-1]
    except:
      persian = ''

    synonyms = b', '.join(detail['synonyms'])
    synonyms = synonyms.decode("utf-8")
    return {'word': word,
      'definitions': definitions,
      'persian': persian,
      'synonyms':synonyms}

def create_note(model, translated_obj):
    my_note = genanki.Note(
      model=model,
      fields=[translated_obj['word'], f'[sound:{translated_obj["word"]}.mp3]'+translated_obj['definitions'], translated_obj['synonyms'], translated_obj['persian']])
    return my_note

def create_note_and_others(audios, my_deck, translated_obj):
  note = create_note(my_model, translated_obj)
  my_deck.add_note(note)
  audios.append(f'{translated_obj["word"]}.mp3')

def main():
  my_deck = deck()
  audios = []
  with open('words') as f:
    for content in f:
      # content = f.readlines()
      # content = content.replace('\n', '')
      content = content.lower().replace('\n', '').strip()
      print(content)
      # try:
      file_path = f'cache/{content}'
      if os.path.exists(file_path):
        with open(file_path) as f:
          cached_data = json.load(f)
          print('use cache')
          create_note_and_others(audios, my_deck, cached_data)
          continue
      try:
        translate = translate_content(content)
      except:
        print(f'error to get {content}')
        time.sleep(15)
        continue
        # raise
      create_note_and_others(audios, my_deck, translate)

      with open(file_path, 'w', encoding='utf8') as outfile:
        json.dump(translate, outfile, ensure_ascii=False)
      # except:
      #   print('error')
      #   passk
      time.sleep(15)

      # break
      # except:
        # print('bug')
  my_package = genanki.Package(my_deck)
  my_package.media_files = audios
  my_package.write_to_file('words-set-1.apkg')

if __name__ == '__main__':
  main()