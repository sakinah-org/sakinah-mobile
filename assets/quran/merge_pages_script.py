#!/usr/bin/env python3
"""
Merges Mushaf page boundaries (from zonetecde/mushaf-layout) into
risan/quran-json per-surah files, producing:

  output/surahs/{1..114}.json   -- original quran-json ayah data + "page" field
  output/page_boundaries.json   -- page (1-604) -> {startSurah, startAyah, endSurah, endAyah}
  output/validation_report.json -- sanity-check results (see FR-7.2 / NFR-2.1)

Source data (already downloaded into this folder by prior steps):
  mushaf_pages/page-001.json .. page-604.json   (source: zonetecde/mushaf-layout)
  chapters/1.json .. chapters/114.json           (source: risan/quran-json)
"""

import json
import glob
import os

MUSHAF_DIR = "mushaf_pages"
CHAPTERS_DIR = "chapters"
OUT_DIR = "output"
OUT_SURAHS_DIR = os.path.join(OUT_DIR, "surahs")

os.makedirs(OUT_SURAHS_DIR, exist_ok=True)


def load_page(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def build_ayah_to_page_index():
    """
    Walk all 604 mushaf-layout pages in order and record, for every
    (surah, ayah) that appears, which page it belongs to.

    Since we already verified (separately) that no ayah is split across
    two pages in this dataset, each (surah, ayah) maps to exactly one
    page. We still detect and report any violation rather than assume it.
    """
    ayah_to_page = {}          # (surah, ayah) -> page
    page_ayah_order = {}       # page -> ordered list of (surah, ayah), de-duplicated consecutive
    conflicts = []             # ayahs that appeared to map to >1 page

    page_files = sorted(
        glob.glob(os.path.join(MUSHAF_DIR, "page-*.json")),
        key=lambda p: int(os.path.basename(p).split("-")[1].split(".")[0]),
    )

    for path in page_files:
        data = load_page(path)
        page_num = data["page"]
        ordered = []
        for line in data.get("lines", []):
            if line.get("type") != "text" or "words" not in line:
                continue
            for w in line["words"]:
                surah_str, ayah_str, _word_str = w["location"].split(":")
                key = (int(surah_str), int(ayah_str))
                if not ordered or ordered[-1] != key:
                    ordered.append(key)

        page_ayah_order[page_num] = ordered

        for key in ordered:
            if key in ayah_to_page and ayah_to_page[key] != page_num:
                conflicts.append(
                    {"surah": key[0], "ayah": key[1],
                     "first_page": ayah_to_page[key], "also_seen_on": page_num}
                )
            ayah_to_page[key] = page_num

    return ayah_to_page, page_ayah_order, conflicts


def build_page_boundaries(page_ayah_order):
    boundaries = {}
    for page_num, ordered in page_ayah_order.items():
        if not ordered:
            continue
        start_surah, start_ayah = ordered[0]
        end_surah, end_ayah = ordered[-1]
        boundaries[str(page_num)] = {
            "startSurah": start_surah,
            "startAyah": start_ayah,
            "endSurah": end_surah,
            "endAyah": end_ayah,
        }
    return boundaries


def enrich_chapters(ayah_to_page):
    missing = []  # ayahs present in quran-json but with no page assigned
    total_ayat = 0

    for surah_num in range(1, 115):
        path = os.path.join(CHAPTERS_DIR, f"{surah_num}.json")
        with open(path, encoding="utf-8") as f:
            chapter = json.load(f)

        for verse in chapter["verses"]:
            ayah_num = verse["id"]
            total_ayat += 1
            key = (surah_num, ayah_num)
            page = ayah_to_page.get(key)
            if page is None:
                missing.append({"surah": surah_num, "ayah": ayah_num})
            verse["page"] = page  # None if missing, surfaced in validation report

        out_path = os.path.join(OUT_SURAHS_DIR, f"{surah_num}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(chapter, f, ensure_ascii=False, indent=1)

    return missing, total_ayat


def validate_monotonic_pages():
    """
    Within each surah, page numbers assigned to consecutive ayat should
    never decrease (reading order should move forward through the Mushaf).
    """
    non_monotonic = []
    for surah_num in range(1, 115):
        path = os.path.join(OUT_SURAHS_DIR, f"{surah_num}.json")
        with open(path, encoding="utf-8") as f:
            chapter = json.load(f)
        prev_page = None
        for verse in chapter["verses"]:
            page = verse["page"]
            if page is None:
                continue
            if prev_page is not None and page < prev_page:
                non_monotonic.append(
                    {"surah": surah_num, "ayah": verse["id"],
                     "page": page, "prev_page": prev_page}
                )
            prev_page = page
    return non_monotonic


def main():
    ayah_to_page, page_ayah_order, conflicts = build_ayah_to_page_index()
    boundaries = build_page_boundaries(page_ayah_order)
    missing, total_ayat = enrich_chapters(ayah_to_page)
    non_monotonic = validate_monotonic_pages()

    with open(os.path.join(OUT_DIR, "page_boundaries.json"), "w", encoding="utf-8") as f:
        json.dump(boundaries, f, ensure_ascii=False, indent=1)

    report = {
        "total_ayat_processed": total_ayat,
        "total_ayat_expected": 6236,
        "pages_indexed": len(page_ayah_order),
        "pages_expected": 604,
        "ayat_with_no_page_assigned": missing,
        "ayat_seen_on_conflicting_pages": conflicts,
        "non_monotonic_page_jumps_within_surah": non_monotonic,
        "status": "PASS" if (
            total_ayat == 6236
            and len(page_ayah_order) == 604
            and not missing
            and not conflicts
            and not non_monotonic
        ) else "FAIL",
    }

    with open(os.path.join(OUT_DIR, "validation_report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=1)

    print(json.dumps(report, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
