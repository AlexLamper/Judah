"""Builds judah_mobile/assets/verses.json from verse_refs.py.

Run: python3 tools/build_verses.py
Every reference is resolved against the bundled KJV and WEB files; a
reference that does not exist fails the build instead of shipping a gap.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from verse_refs import TOPICS, TOPIC_LABELS  # noqa: E402

ASSETS = os.path.join(HERE, "..", "judah_mobile", "assets")
kjv = json.load(open(os.path.join(ASSETS, "bible", "kjv.json"), encoding="utf-8"))
web = json.load(open(os.path.join(ASSETS, "bible", "web.json"), encoding="utf-8"))
book_index = {b["name"]: i for i, b in enumerate(kjv["books"])}

REF = re.compile(r"^(.+) (\d+):(\d+)(?:-(\d+))?$")


def resolve(ref):
    m = REF.match(ref)
    if not m:
        raise ValueError(f"bad reference: {ref}")
    book, chap, start, end = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
    end = int(end) if end else start
    if book not in book_index:
        raise ValueError(f"unknown book in {ref}")
    if end - start > 2:
        raise ValueError(f"too long for a widget: {ref}")
    b = book_index[book]
    texts = {}
    for name, bible in (("kjv", kjv), ("web", web)):
        chapters = bible["books"][b]["chapters"]
        if chap > len(chapters) or end > len(chapters[chap - 1]):
            raise ValueError(f"{ref} not found in {name}")
        texts[name] = " ".join(chapters[chap - 1][v - 1] for v in range(start, end + 1))
        if not texts[name]:
            raise ValueError(f"{ref} empty in {name}")
    # Display reference uses the singular "Psalm" like most Bible apps.
    display = ref.replace("Psalms ", "Psalm ")
    return {"ref": display, "book": b, "chapter": chap, "start": start, "end": end, **texts}


verses = {}
for topic, refs in TOPICS.items():
    if len(refs) != len(set(refs)):
        raise ValueError(f"duplicate reference inside {topic}")
    for ref in refs:
        if ref not in verses:
            verses[ref] = resolve(ref)
            verses[ref]["topics"] = []
        verses[ref]["topics"].append(topic)

out = {
    "topics": [{"id": t, "label": TOPIC_LABELS[t]} for t in TOPICS],
    "verses": list(verses.values()),
}
path = os.path.join(ASSETS, "verses.json")
json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(out['verses'])} unique verses across {len(TOPICS)} topics -> {path}")
