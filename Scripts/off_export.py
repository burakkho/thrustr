#!/usr/bin/env python3
"""
Export a snapshot of foods from OpenFoodFacts into Nutrition/foods.csv

Usage:
  python3 Scripts/off_export.py --out Nutrition/foods.csv --limit 80

Notes:
- No external deps (uses urllib). Respects OFF API via lightweight queries.
- Prioritizes Turkish locale; falls back naturally based on OFF content.
- Deduplicates by barcode, maps categories to app's FoodCategory enums.
"""

import argparse
import csv
import json
import math
import time
import urllib.parse
import urllib.request
from typing import Dict, Any, List, Set

USER_AGENT = "SporHocamSnapshot/1.0 (+https://sporhocam.app)"
SEARCH_URL = "https://world.openfoodfacts.org/cgi/search.pl"


def fetch_off_search(query: str, page_size: int, lc: str) -> List[Dict[str, Any]]:
    params = {
        "search_terms": query,
        "search_simple": "1",
        "action": "process",
        "json": "1",
        # Request only fields we map
        "fields": "code,product_name,brands,nutriments,image_small_url,last_modified_t,lc,categories_tags",
        "page_size": str(page_size),
        "lc": lc,
    }
    url = SEARCH_URL + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        if resp.status < 200 or resp.status >= 300:
            raise RuntimeError(f"OFF search failed: HTTP {resp.status}")
        data = json.loads(resp.read().decode("utf-8"))
        products = data.get("products", [])
        return products


def first_brand(brands_field: str) -> str:
    if not brands_field:
        return ""
    # OFF uses comma-separated brands
    parts = [p.strip() for p in brands_field.split(",") if p.strip()]
    return parts[0] if parts else ""


CATEGORY_MAP = {
    "meat": "meat",
    "beef": "meat",
    "poultry": "meat",
    "chicken": "meat",
    "turkey": "meat",
    "lamb": "meat",
    "pork": "meat",
    "dairy": "dairy",
    "milk": "dairy",
    "cheese": "dairy",
    "yogurt": "dairy",
    "grain": "grains",
    "cereal": "grains",
    "rice": "grains",
    "pasta": "grains",
    "bread": "bakery",
    "bakery": "bakery",
    "vegetable": "vegetables",
    "legume": "vegetables",
    "salad": "vegetables",
    "fruit": "fruits",
    "nut": "nuts",
    "beverage": "beverages",
    "drink": "beverages",
    "juice": "beverages",
    "snack": "snacks",
    "confectionery": "snacks",
    "chocolate": "snacks",
    "sweet": "desserts",
    "dessert": "desserts",
    "sauce": "condiments",
    "condiment": "condiments",
    "seafood": "seafood",
    "fish": "seafood",
    "fast-food": "fastfood",
    # Turkish cuisine hint
    "turkish-cuisine": "turkish",
}


def map_category(categories_tags: List[str]) -> str:
    if not categories_tags:
        return "other"
    tags = [t.lower() for t in categories_tags]
    # Heuristic: find the first tag that maps
    for tag in tags:
        for key, value in CATEGORY_MAP.items():
            if key in tag:
                return value
    return "other"


DEFAULT_QUERIES_TR = [
    # Temel protein kaynakları
    "tavuk göğsü", "hindi göğsü", "yumurta", "yoğurt", "süt", "peynir", "lor peyniri", "kefir",
    # Bakliyat
    "nohut", "mercimek", "kuru fasulye", "barbunya",
    # Tahıllar
    "pirinç", "bulgur", "yulaf", "tam buğday ekmeği", "makarna",
    # Sağlıklı yağlar
    "zeytinyağı", "avokado",
    # Kuruyemiş
    "badem", "fındık", "ceviz",
    # Meyve & sebze (örnek büyük hacimliler)
    "muz", "elma", "portakal", "çilek", "ıspanak", "brokoli", "domates", "salatalık",
    # Deniz ürünleri & konserve
    "ton balığı", "somon",
]


def to_float(value: Any) -> float:
    try:
        f = float(value)
        if math.isnan(f) or math.isinf(f):
            return 0.0
        return f
    except Exception:
        return 0.0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="Nutrition/foods.csv", help="Output CSV path")
    parser.add_argument("--limit", type=int, default=60, help="Max items per query")
    parser.add_argument("--lc", default="tr", help="Preferred locale (default: tr)")
    args = parser.parse_args()

    seen: Set[str] = set()
    rows: List[List[str]] = []

    for idx, q in enumerate(DEFAULT_QUERIES_TR):
        try:
            products = fetch_off_search(q, args.limit, args.lc)
        except Exception as e:
            print(f"WARN: query '{q}' failed: {e}")
            continue

        for p in products:
            code = (p.get("code") or "").strip()
            # Dedup by barcode; skip empties
            if not code or code in seen:
                continue

            nutr = p.get("nutriments") or {}
            kcal = to_float(nutr.get("energy-kcal_100g"))
            prot = to_float(nutr.get("proteins_100g"))
            carb = to_float(nutr.get("carbohydrates_100g"))
            fat = to_float(nutr.get("fat_100g"))

            # Require at least calories; keep sparse but usable items
            if kcal <= 0 and (prot <= 0 and carb <= 0 and fat <= 0):
                continue

            name = (p.get("product_name") or "").strip()
            if not name:
                continue

            brand = first_brand((p.get("brands") or "").strip())
            categories_tags = p.get("categories_tags") or []
            category = map_category(categories_tags)

            rows.append([
                name,                 # nameEN
                name,                 # nameTR (same if not localized)
                brand,
                f"{kcal}",
                f"{prot}",
                f"{carb}",
                f"{fat}",
                category,
            ])
            seen.add(code)

        # Be nice to OFF
        time.sleep(0.5)

    # Write CSV (header + rows)
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["nameEN","nameTR","brand","calories","protein","carbs","fat","category"])
        writer.writerows(rows)

    print(f"DONE: wrote {len(rows)} rows to {args.out}")


if __name__ == "__main__":
    main()


