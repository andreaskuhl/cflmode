# Das Skript überprüft:
# - Welche Sprachschlüssel in Lua-Quellcode verwendet werden (STR("Key"), wConfig.add*Field("key"), wConfig.addStaticText("Key"))
# - Welche Schlüssel in der deutschen Sprachdatei de.lua definiert sind
# - Ob alle verwendeten Schlüssel auch in de.lua vorhanden sind und umgekehrt
# - Ob andere Sprachdateien (i18n/??.lua) dieselben Schlüssel wie de.lua enthalten

import re
import os
import glob
from collections import defaultdict

language_path = 'i18n/??.lua'
language_reference = 'de.lua'
code_path_lib = 'lib/*.lua'
code_main = 'main.lua'


def extract_keys_from_lua_file(filepath):
    # - Liest eine Lua-Datei (z. B. de.lua)
    # - Extrahiert alle Schlüssel der Form key = "Text" (Regex basiert)
    # - Gibt ein Set der gefundenen Schlüssel zurück

    try:
        with open(filepath, encoding='utf-8') as f:
            content = f.read()
        return set(re.findall(r'^\s*([a-zA-Z0-9_.-]+)\s*=\s*".*?"', content, re.MULTILINE))
    except Exception as e:
        print(f"Fehler beim Lesen von {filepath}: {e}")
        return set()


def extract_str_keys_from_lua_sources(paths):
    # - Durchsucht Lua-Quellcode-Dateien nach:
    # - STR("key")
    # - wConfig.add*Field("key") → wandelt ersten Buchstaben in Großbuchstaben um
    # - wConfig.addStaticText("key")
    # - Speichert, in welchen Dateien jeder Schlüssel verwendet wurde
    # - Gibt ein Set der verwendeten Schlüssel und ein Mapping key → Dateien zurück

    str_keys = set()
    key_sources = defaultdict(set)  # key → set of filenames
    for path in paths:
        try:
            with open(path, encoding='utf-8') as f:
                content = f.read()

            # STR("key")
            for match in re.findall(r'STR\s*\(\s*"([^"]+)"\s*\)', content):
                str_keys.add(match)
                key_sources[match].add(path)

            # wConfig.add*Field("key") — erster Buchstabe groß
            for match in re.findall(r'wConfig\.add\w+Field\s*\(\s*"([^"]+)"', content):
                key = match[0].upper() + match[1:]
                str_keys.add(key)
                key_sources[key].add(path)

            # wConfig.addStaticText("key")
            for match in re.findall(r'wConfig\.addStaticText\s*\(\s*"([^"]+)"', content):
                str_keys.add(match)
                key_sources[match].add(path)

            # wConfig.addLine("key")
            for match in re.findall(r'wConfig\.addLine\s*\(\s*"([^"]+)"', content):
                str_keys.add(match)
                key_sources[match].add(path)

            # wConfig.startPanel("key")
            for match in re.findall(r'wConfig\.startPanel\s*\(\s*"([^"]+)"', content):
                str_keys.add(match)
                key_sources[match].add(path)

        except Exception as e:
            print(f"Fehler beim Lesen von {path}: {e}")
    return str_keys, key_sources


# Pfade definieren
de_keys = extract_keys_from_lua_file('i18n/de.lua')
lua_source_files = [code_main] + glob.glob(code_path_lib, recursive=False)
str_keys_used, key_sources = extract_str_keys_from_lua_sources(lua_source_files)

# STR()-Verwendung prüfen
unused_in_code = de_keys - str_keys_used
missing_in_de = str_keys_used - de_keys

# Sprachvergleich: alle ?? außer de
lang_files = glob.glob(language_path)
print(f"\n\033[93m Key anderer Sprachdatei nicht definiert\033[0m - Keys in de.lua, aber nicht in *.lua:")
print("  ", lang_files)
ok = True
for lang_path in lang_files:
    if os.path.basename(lang_path) == language_reference:
        continue
    lang_code = os.path.splitext(os.path.basename(lang_path))[0]
    lang_keys = extract_keys_from_lua_file(lang_path)
    missing_in_lang = de_keys - lang_keys

    if len(missing_in_lang) != 0:
        ok = False
        for key in sorted(missing_in_lang):
            print(f"\033[91m  - {key} (i18n/{lang_code}.lua)\033[0m")
if ok:
    print("\033[92m  OK!\033[0m")


print(f"\n\033[93m Zusätzliche Keys in anderen Sprachdateien\033[0m - Keys in *.lua, aber nicht in de.lua:")
ok_extra = True
for lang_path in lang_files:
    if os.path.basename(lang_path) == language_reference:
        continue
    lang_code = os.path.splitext(os.path.basename(lang_path))[0]
    lang_keys = extract_keys_from_lua_file(lang_path)
    extra_keys = lang_keys - de_keys

    if len(extra_keys) != 0:
        ok_extra = False
        for key in sorted(extra_keys):
            print(f"\033[91m  + {key} (nur in: i18n/{lang_code}.lua)\033[0m")
if ok_extra:
    print("\033[92m  OK!\033[0m")


# STR()-Verwendung ausgeben
print("\n\033[93m Key nicht definiert\033[0m - Keys per STR() oder wConfig.add* verwendet, aber in de.lua nicht definiert:")
print("  ", lua_source_files)
if len(missing_in_de) == 0:
    print("\033[92m  OK!\033[0m")
else:
    for key in sorted(missing_in_de):
        files = ", ".join(sorted(key_sources[key]))
        print(f"\033[91m  - {key} (verwendet in: {files})\033[0m")

print("\n\033[93m Key nicht verwendet\033[0m - Keys in de.lua definiert, aber nicht per STR() oder wConfig.add* verwendet:")
print("  ", lua_source_files)
if len(unused_in_code) == 0:
    print("\033[92m  OK!\033[0m")
else:
    for key in sorted(unused_in_code):
        print(f"\033[91m  + {key} (definiert in: i18n/de.lua)\033[0m")

print("\n")
