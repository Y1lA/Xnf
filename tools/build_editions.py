#!/usr/bin/env python3
"""يبني Resources/editions.json من بلاي ليست «اصدارات المفكر».

- يقرأ البلاي ليست PLENUCyfnKyFs (٥٠ فيديو، كل فيديو = إصدار).
- يطابق رقم الإصدار من عنوان الفيديو نفسه (مش من ترتيب البلاي ليست).
- يجيب مدة كل فيديو من صفحة البلاي ليست.
- يوزّع ٤٨ سؤال على مدة الفيديو توزيع تقديري (التوقيتات قابلة للتصحيح من التطبيق).
"""

import json
import os
import re
import sys
import unicodedata
import urllib.request

PLAYLIST = "PLENUCyfnKyFs"
QUESTIONS_PER_EDITION = 48
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")
INTRO_SECONDS = 25   # مقدمة الفيديو قبل بداية شرح السؤال الأول
TAIL_SECONDS = 40    # نهاية الفيديو بعد شرح السؤال الأخير
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "Resources", "editions.json")

ARABIC_DIGITS = "٠١٢٣٤٥٦٧٨٩"


def fetch(url):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept-Language": "ar,en;q=0.9",
    })
    with urllib.request.urlopen(req, timeout=40) as resp:
        return resp.read().decode("utf-8", "ignore")


def to_ascii_digits(text):
    out = []
    for ch in text:
        if ch in ARABIC_DIGITS:
            out.append(str(ARABIC_DIGITS.index(ch)))
        elif unicodedata.category(ch) == "Nd" and ch.isdigit():
            try:
                out.append(str(unicodedata.digit(ch)))
            except Exception:
                out.append(ch)
        else:
            out.append(ch)
    return "".join(out)


def edition_number(title):
    m = re.search(r"(?:الاصدار|الإصدار|اصدار|إصدار|النسخة|نسخة)\s*[^\d]{0,8}(\d{1,3})",
                  to_ascii_digits(title))
    return int(m.group(1)) if m else None


def parse_duration(text):
    parts = [int(p) for p in text.split(":")]
    if len(parts) == 3:
        return parts[0] * 3600 + parts[1] * 60 + parts[2]
    if len(parts) == 2:
        return parts[0] * 60 + parts[1]
    return 0


def main():
    print("fetching playlist …")
    html = fetch("https://www.youtube.com/playlist?list=%s&hl=ar" % PLAYLIST)

    ids = []
    for m in re.finditer(r'"videoId":"([A-Za-z0-9_-]{11})"', html):
        if m.group(1) not in ids:
            ids.append(m.group(1))
    print("video ids:", len(ids))

    vid_pos = []
    for vid in ids:
        vid_pos.append(html.find('"videoId":"%s"' % vid))
    vid_pos.sort()

    durations = {}
    for i, vid in enumerate(ids):
        start = html.find('"videoId":"%s"' % vid)
        if start < 0:
            continue
        nxt = [p for p in vid_pos if p > start]
        end = nxt[0] if nxt else start + 8000
        window = html[start:end]
        m = re.search(r'"text":"(\d{1,2}:\d{2}(?::\d{2})?)"', window)
        if m:
            durations[vid] = parse_duration(m.group(1))

    editions = {}
    for vid in ids:
        title = ""
        try:
            meta = json.loads(fetch(
                "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=%s&format=json" % vid))
            title = meta.get("title", "")
        except Exception as exc:  # noqa: BLE001
            print("oembed failed", vid, exc)
        num = edition_number(title)
        if num is None:
            print("!! could not read edition number:", vid, title)
            continue
        editions[num] = {
            "number": num,
            "videoID": vid,
            "title": title,
            "duration": durations.get(vid, 0),
        }

    missing = [n for n in range(1, 51) if n not in editions]
    if missing:
        print("missing editions:", missing)
        sys.exit(1)

    for num, ed in editions.items():
        dur = ed["duration"]
        if dur <= 0:
            dur = ed["duration"] = 45 * 60
        span = max(dur - INTRO_SECONDS - TAIL_SECONDS, QUESTIONS_PER_EDITION * 10)
        stamps = []
        for q in range(QUESTIONS_PER_EDITION):
            stamps.append(int(round(INTRO_SECONDS + q * span / QUESTIONS_PER_EDITION)))
        ed["timestamps"] = stamps

    data = {
        "playlist": PLAYLIST,
        "channel": "صالحة عسيري",
        "questionsPerEdition": QUESTIONS_PER_EDITION,
        "estimated": True,
        "editions": [editions[n] for n in sorted(editions)],
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
        fh.write("\n")

    for ed in data["editions"]:
        print("%2d | %s | %5ds | %s" % (ed["number"], ed["videoID"], ed["duration"], ed["title"]))
    print("wrote", OUT)

    # تحقق: الإصدار ٥ طوله 44:36 حسب البلاي ليست
    e5 = editions[5]["duration"]
    print("check edition 5 duration =", e5, "(expected 2676)", "OK" if e5 == 2676 else "MISMATCH")


if __name__ == "__main__":
    main()
