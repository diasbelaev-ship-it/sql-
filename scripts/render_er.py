"""Render a compact ER overview to PNG using Pillow (optional, SQL does not require Python)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "er-diagram.png"
W, H = 1600, 1080
im = Image.new("RGB", (W, H), "#FFFFFF")
d = ImageDraw.Draw(im)
font_dir = Path("C:/Windows/Fonts")
title = ImageFont.truetype(str(font_dir / "arialbd.ttf"), 34)
head = ImageFont.truetype(str(font_dir / "arialbd.ttf"), 22)
body = ImageFont.truetype(str(font_dir / "arial.ttf"), 17)
small = ImageFont.truetype(str(font_dir / "arial.ttf"), 14)

boxes = {
    "GYMS": (590, 120, ["PK id", "name, address", "lat, lng, price_band"]),
    "PLANS": (1080, 120, ["PK id · FK gym_id", "audience, price_kzt", "price_basis"]),
    "TRAINERS": (100, 330, ["PK id · FK gym_id", "full_name, specialty"]),
    "CLASSES": (590, 360, ["PK id · FK gym_id", "FK trainer_id, weekday"]),
    "GYM_AMENITIES": (1080, 350, ["PK/FK gym_id", "PK amenity_code"]),
    "CLIENTS": (100, 610, ["PK id", "email, segment"]),
    "MEMBERSHIPS": (590, 630, ["PK id · FK client_id", "FK plan_id, dates"]),
    "PAYMENTS": (1080, 640, ["PK id", "FK membership_id", "amount_kzt"]),
    "REVIEWS": (100, 860, ["PK id", "FK client_id, gym_id", "rating"]),
    "BOOKINGS": (590, 870, ["PK id", "FK client_id, class_id", "booked_for"]),
}
BW, BH = 320, 140

def point(key, side):
    x, y, _ = boxes[key]
    return {"left": (x, y + BH//2), "right": (x+BW, y+BH//2),
            "top": (x+BW//2, y), "bottom": (x+BW//2, y+BH)}[side]

def link(parent, child, start, end, via=None):
    pts = [point(parent, start)] + (via or []) + [point(child, end)]
    d.line(pts, fill="#62748A", width=3, joint="curve")
    x, y = pts[-1]
    d.ellipse((x-5,y-5,x+5,y+5), fill="#2563A6")

d.text((74, 30), "GymFinder Алматы — ER-диаграмма", font=title, fill="#14283E")
d.text((76, 78), "10 таблиц  ·  сплошная связь = внешний ключ  ·  данные залов и учебные записи разделены", font=body, fill="#516275")

link("GYMS", "PLANS", "right", "left")
link("GYMS", "TRAINERS", "left", "top", [(260,190),(260,330)])
link("GYMS", "CLASSES", "bottom", "top")
link("GYMS", "GYM_AMENITIES", "right", "top", [(1010,190),(1010,320),(1240,320)])
link("GYMS", "REVIEWS", "left", "left", [(60,190),(60,930)])
link("TRAINERS", "CLASSES", "right", "left")
link("CLIENTS", "MEMBERSHIPS", "right", "left")
link("CLIENTS", "REVIEWS", "bottom", "top")
link("CLIENTS", "BOOKINGS", "bottom", "left", [(260,820),(550,820),(550,940)])
link("PLANS", "MEMBERSHIPS", "bottom", "top", [(1020,260),(1020,580),(750,580)])
link("MEMBERSHIPS", "PAYMENTS", "right", "left")
link("CLASSES", "BOOKINGS", "bottom", "top", [(950,500),(950,820),(750,820)])

for name, (x, y, fields) in boxes.items():
    d.rounded_rectangle((x,y,x+BW,y+BH), radius=12, fill="#F5F9FD", outline="#9DB2C8", width=2)
    d.rounded_rectangle((x,y,x+BW,y+40), radius=12, fill="#173B61")
    d.rectangle((x,y+28,x+BW,y+40), fill="#173B61")
    d.text((x+14,y+8), name, font=head, fill="white")
    for i, field in enumerate(fields):
        d.text((x+15,y+51+i*25), field, font=body, fill="#27384B")

d.text((80, 1035), "Источник связей: db/migrations/001_schema.sql  ·  PK — первичный ключ  ·  FK — внешний ключ", font=small, fill="#5A6D80")
OUT.parent.mkdir(parents=True, exist_ok=True)
im.save(OUT)
print(OUT)
