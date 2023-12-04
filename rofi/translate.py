#!/usr/bin/env python3
import sys
import os
import re
import json
from os import listdir
from os.path import isfile, join
from textwrap import wrap
from subprocess import PIPE, Popen


class Translator:

    last = ["Synonyms", "Examples","See also", "EOF"]

    def __init__(self, concept):
        self.concept = concept

    def translate_second_language(self, source='en', destination='fa'):
        concept = self.concept.lower()
        #if concept.find(" ") != -1:
        #    return
        query = "trans -no-auto -d {}:{} '{}'".format(source, destination, concept)
        #asdf = os.popen(query)
        translation = Popen(query, shell=True, stdout=PIPE).stdout.read().decode('utf8')
        tr = ParseTranslation(translation)
        line = tr.next_line()
        return line.strip().replace('\x1b[22m','').replace('\x1b[1m','').strip()

    def retrieve_defs(self, language='en'):
        concept = self.concept.lower().replace('\n', '').strip()
        #if concept.find(" ") != -1:
        #    return
        query = f"trans -d {language}:{language} '{concept}'"
        # print(query)
        #asdf = os.popen(query)
        translation = Popen(query, shell=True, stdout=PIPE).stdout.read().decode('utf8')
        tr = ParseTranslation(translation)
        concept = tr.get_concept().strip('\t\r\n\0')
        if not concept:
            return
        # This is to remove the "null" that appears after the change in google translate
        concept = concept.split()[0]
        aux = tr.next_line()
        prefix = self.pref(aux)
        if prefix == "":
            return
        line = self.normalize(tr.next_line())
        n_def = 0  # Number of definitions
        rv = {}
        rv = {'word': concept}
        rv['definitions'] = []
        rv['synonyms'] = []
        rv['examples'] = []
        while True:
            n_def += 1
            if not line:
                break
            example = self.parse_example(tr.next_line(), concept, language)
            if not example:
                tr.go_back()
            rv['definitions'].append("{}{}{}".format(prefix, line, example))
            line = tr.next_line()
            if line in Translator.last:
                # print (1, line)
                break
            if self.pref(line) == "":
                while line != "":
                    line = tr.next_line()
                line = tr.next_line()
                if line in Translator.last:
                    if line == 'Synonyms':
                        line = tr.next_line()
                        line = tr.next_line()
                        line = line.replace(' - ', '').strip()
                        items = line.replace('\x1b[1m','').replace('\x1b[22m', '').split(', ')
                        for sub_item in items:
                            rv['synonyms'].append(sub_item.encode('utf-8'))
                    if line == 'Examples':
                        for i in range(5):
                            line = tr.next_line()
                            line = line.replace(' - ', '').strip()
                            rv['examples'].append(line)
                    break
            new_prefix = self.pref(line)
            if new_prefix != "":  # Change of prefix
                prefix = new_prefix
                line = self.normalize(tr.next_line())
            else:
                line = self.normalize(line)
        # while True:
        #     n_def += 1
        #     if not line:
        #         break
        #     example = self.parse_example(tr.next_line(), concept, language)
        #     if not example:
        #         tr.go_back()
        #     definitions.append("{}{}{}".format(prefix, line, example))
        #     line = tr.next_line()
        #     if line in Translator.last:
        #         break
        #     if self.pref(line) == "":
        #         while line != "":
        #             line = tr.next_line()
        #         line = tr.next_line()
        #         if line in Translator.last:
        #             break
        #     new_prefix = self.pref(line)
        #     if new_prefix != "":  # Change of prefix
        #         prefix = new_prefix
        #         line = self.normalize(tr.next_line())
        #     else:
        #         line = self.normalize(line)
        return rv

    def pref(self, x):
        return {
            "noun": "(n.) ",
            "suffix": "(suf.) ",
            "prefix": "(prefix) ",
            "verb": "(v.) ",
            "adjective": "(adj.) ",
            "abbreviation": "(abbrev.) ",
            "adverb": "(adv.) ",
            "preposition": "(prep.) ",
            "pronoun": "(pron.) ",
            "article": "(article) ",
            "exclamation": "(excl.) ",
            "conjunction": "(conj.) "
        }.get(x, "")   # "" is default if x not found

    def normalize(self, line):
        # Remove first and last "words" which are format tags
        return line.rsplit('.', 1)[0].split(' ', 1)[1].strip()

    def parse_example(self, example, concept, language):
        if example[:11] == '        - \"':   # If there is example
            # This removes the concept or variations of it
            example = example.split("\"")[1]

            def remove_pattern(example, concept):
                # This is so words that contain concept or a conjugation of it
                # as a substring are not removed
                dots = "....."
                regex = re.compile("(^|[^a-zA-Z])" + concept +"([^a-zA-Z]|$)", re.IGNORECASE)
                return regex.sub("\g<1>{}\g<2>".format(dots), example)

            # remove concept variations
            if language == 'en':
                example = remove_pattern(example, concept + 's')
                example = remove_pattern(example, concept + "es")

                if concept[-1] == 'e':
                    example = remove_pattern(example, concept + "d")
                    example = remove_pattern(example, concept[:-1] + "ing")

                example = remove_pattern(example, concept + "ed")
                example = remove_pattern(example, concept + concept[-1] + "ed")
                example = remove_pattern(example, concept + "ing")
                example = remove_pattern(example, concept + concept[-1] + "ing")
                if concept[-1] == 'f':
                    example = remove_pattern(example, concept[:-1] + "ves")
                if concept[-1] == 'fe':
                    example = remove_pattern(example, concept[:-2] + "ves")
                example = remove_pattern(example, concept[:1] + concept[-1] + "ing")
                if concept[-1] == 'y':
                    example = remove_pattern(example, concept[:-1] + "ies")
                    example = remove_pattern(example, concept[:-1] + "ied")
                example = remove_pattern(example, concept)

            return " (e.g. " + example + ")"
        else:
            return ''

    # PC support
    def send_to_file(self, card_lines, concept):
        f = open(Translator.target_file, 'a')
        for line in card_lines:
            f.write("\"{}\"; {}\n".format(line, concept))
        f.close()

    # PC support
    def ask_user(self, n_def, definitions, concept):
        card_lines = []
        if n_def == 1:
            definitions = definitions.replace("\\\"", "\"")[7:-2]
            confirm = os.system('''zenity --question --ok-label=\"Ok\" --cancel-label=\"Cancel\"  --height=10 --text=\" The following card will be added:\n {} \"'''
                                .format(definitions.replace("\"", "\\\"")))
            if confirm == 0:
                card_lines.append(definitions)
        elif n_def > 1:
            lines = os.popen("zenity  --list --text '{} - Select definitions to be updated to Anki's database' --checklist --column \"Pick\" --column \"Definitions\" {} --width=1000 --height=450".format(concept, definitions)).read()
            card_lines = lines[:-1].split('|')
        else:  # no definitions found
            os.system("zenity --question --ok-label=\"Ok\" --cancel-label=\"Cancel\"  --height=10 --text=\"No definitions were found for \\\"{}\\\" \"".format(concept))
        return card_lines

    def translate(self):
        rv = self.retrieve_defs()
        persian = self.translate_second_language()
        if not rv and persian:
            rv = {}
        elif not rv:
            return
        rv['persian'] = persian
        if 'synonyms' not in rv:
            rv['synonyms'] = []
        synonyms = b', '.join(rv['synonyms']).decode("utf-8")
        rv['synonyms'] = synonyms.split(', ')
        return rv

    # def translate(self):
    #     rv = self.retrieve_defs()
    #     persian = self.translate_second_language()
    #     if persian and not rv:
    #         rv = {}
    #         rv['definitions'] = []
    #         rv['synonyms'] = []
    #         rv['examples'] = []
    #     rv['persian'] = persian
    #     return rv

    def render_translate(self):
        rv = self.retrieve_defs()
        try:
            rv['persian'] = self.translate_second_language()
        except:
            rv['persian'] = ''

        return Translator.render(rv)
        

    @staticmethod
    def render(translation):
        wrapped_definitions = []
        print(translation)
        if type(translation['definitions']) != list:
            translation['definitions'] = translation['definitions'].split('<br/>')
        for definition in translation['definitions']:
            wrapped = wrap(definition, 90)
            wrapped.append('-------')
            wrapped_definitions.append('\n'.join(wrapped))
        definitions = '\n'.join(wrapped_definitions)
        if type(translation['synonyms'])==list:
            synonyms = wrap(', '.join(translation['synonyms']))
        else:
            synonyms = wrap(translation['synonyms'])

        result = f"""{translation['word']}
        {translation['persian']}

# definitions:
{definitions}

# synonyms:
{synonyms}
        """

        return result

class ParseTranslation:

    def __init__(self, translation):
        self.translation = translation.split('\n')
        self.counter = -1
        self.concept = self.next_line().lower()
        phonetic = self.next_line()
        # If there was a phonetic line, extra read
        if len(phonetic) > 0:  # and phonetic[0] == '/': TODO check that this extra condition is not neccesary
            self.next_line()

    def next_line(self):
        self.counter += 1
        try:
            return self.translation[self.counter]
        except IndexError:
            return 'EOF'

    def go_back(self):
        self.counter -= 1

    def get_concept(self):
        return self.concept


def get_translate_from_cache_or_translate_directly(word):
    file_path = f'/home/efazati/.config/rofi/cache/{word}'
    if os.path.exists(file_path):
        with open(file_path) as f:
            cached_data = json.load(f)
            return Translator.render(cached_data)
    rv = Translator(word).translate()
    with open(file_path, 'w', encoding='utf8') as outfile:
        json.dump(rv, outfile, ensure_ascii=False)
    return Translator.render(rv)


if __name__ == "__main__":
    word = sys.argv[-1]
    defs = get_translate_from_cache_or_translate_directly(word)
    print(defs)
    try:
        word = sys.argv[-1]
        defs = get_translate_from_cache_or_translate_directly(word)
        print(defs)
    except Exception as e:
        print(str(e))
        print('errrrorrr')
        file_path = '/home/efazati/.config/rofi/cache/'

        os.chdir(file_path)
        files = filter(os.path.isfile, os.listdir(file_path))
        files = [os.path.join(file_path, f) for f in files] # add path to each file
        files.sort(key=lambda x: os.path.getmtime(x))
        my_files = []
        for f in files:
            my_files.insert(0, f.split('/')[-1])
        print('\n'.join(my_files))
