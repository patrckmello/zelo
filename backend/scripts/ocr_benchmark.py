# As tabelas de amostras ficam uma por linha para leitura; o gerador
# pseudoaleatório é intencional (sementes fixas, sem uso criptográfico).
# ruff: noqa: E501, S311
"""Comparativo reproduzível da leitura de embalagens (OCR).

Gera embalagens fictícias "fotografadas" (perspectiva, reflexo, pouca luz,
desfoque, validade impressa em pontinhos e texto girado na aba) com gabarito
de nome, validade e quantidade, e mede a API Zelo em execução.

Uso (na pasta backend/):

    python -m scripts.ocr_benchmark gerar --conjunto ajuste
    python -m scripts.ocr_benchmark gerar --conjunto validacao
    python -m scripts.ocr_benchmark medir --conjunto validacao --api http://localhost:8000

O conjunto "ajuste" foi usado para calibrar o interpretador; o de "validação"
não. Para comparar motores, suba a API com ZELO_OCR_ENGINE=tesseract ou
rapidocr e meça de novo. As imagens ficam em `.ocr-benchmark/` (fora do Git).
A conta usada é a de demonstração do `.env`; a senha nunca é impressa.
Fontes: Arial e Consolas do Windows por padrão (`--fontes` para outra pasta).
"""

import argparse
import json
import random
import sys
import time
import unicodedata
from pathlib import Path
from typing import Any

import cv2
import httpx
import numpy as np
from PIL import Image, ImageDraw, ImageFont

BACKEND_DIR = Path(__file__).resolve().parent.parent
OUTPUT_DIR = BACKEND_DIR / ".ocr-benchmark"

AJUSTE: list[dict[str, Any]] = [
    dict(id="01-dipirona-limpa", brand="Dipirona Monoidratada", brand_size=100, dose="500 mg",
         qty_text="Contém 20 comprimidos", exp_text="FAB: 03/2025   VAL: 03/2027   LOTE: AB1234",
         bg="white", ink="#1b1b1b", band="#c62828", persp=0.03, exp_at=(60, 700),
         gt=dict(name="Dipirona Monoidratada", exp="2027-03-31", qty=20)),
    dict(id="02-loratadina-aba-pontinhos", brand="Loratadina", dose="10 mg", qty_text="12 comprimidos",
         exp_text="VAL 08/27 L:8812", dots=True, exp_rotate=90, exp_at=(1250, 230), bg="#e8f1fb",
         ink="#0d3b66", band="#0d3b66", persp=0.07, glare=(0.35, 0.3, 0.12),
         gt=dict(name="Loratadina", exp="2027-08-31", qty=12)),
    dict(id="03-paracetamol-pontinhos", brand="Paracetamol", dose="750 mg",
         qty_text="Contém 20 comprimidos revestidos", exp_text="FAB 01/25  VAL 01/28  L 2231", dots=True,
         exp_at=(700, 560), bg="white", ink="#003a70", band="#e30613", persp=0.08,
         glare=(0.6, 0.5, 0.15), blur=1.0, gt=dict(name="Paracetamol", exp="2028-01-31", qty=20)),
    dict(id="04-ibuprofeno-pouca-luz", brand="Ibuprofeno", dose="400 mg", qty_text="10 cápsulas gelatinosas",
         exp_text="Val.: 11/2026", bg="#fff3e0", ink="#5d2c00", band="#ef6c00", light=0.55, noise=14,
         persp=0.05, gt=dict(name="Ibuprofeno", exp="2026-11-30", qty=10)),
    dict(id="05-amoxicilina-desfoque", brand="Amoxicilina", dose="500 mg", qty_text="21 cápsulas",
         exp_text="VENC: 05/2026", exp_size=30, bg="white", ink="#222222", band="#2e7d32", blur=2.2,
         persp=0.05, gt=dict(name="Amoxicilina", exp="2026-05-31", qty=21)),
    dict(id="06-omeprazol-perspectiva", brand="Omeprazol", dose="20 mg", qty_text="28 cápsulas",
         exp_text="V: 09/27  L: OM771", dots=True, exp_at=(720, 560), bg="#f3e5f5", ink="#4a148c",
         band="#6a1b9a", persp=0.16, rotate=-14, gt=dict(name="Omeprazol", exp="2027-09-30", qty=28)),
    dict(id="07-losartana-marca", brand="Losartana Potássica", brand_size=96, dose="50 mg",
         qty_text="30 comprimidos revestidos", exp_text="VAL 12/2027", bg="white", ink="#0b5345",
         band="#117864", glare=(0.3, 0.45, 0.1), persp=0.06,
         gt=dict(name="Losartana Potássica", exp="2027-12-31", qty=30)),
    dict(id="08-simeticona-frasco", brand="Simeticona", dose="75 mg/mL", qty_text="Frasco com 15 mL",
         exp_text="VAL 02/2027  LOTE 5521", dots=True, exp_rotate=-90, exp_at=(1240, 200), bg="#e0f7fa",
         ink="#006064", band="#00838f", persp=0.06, gt=dict(name="Simeticona", exp="2027-02-28", qty=None)),
]  # fmt: skip

VALIDACAO: list[dict[str, Any]] = [
    dict(id="h1-cetirizina-aba", brand="Cetirizina", dose="10 mg", qty_text="10 comprimidos revestidos",
         exp_text="VAL 06/2027 L:C442", dots=True, exp_rotate=90, exp_at=(1250, 260), bg="#fffde7",
         ink="#33691e", band="#558b2f", persp=0.06, gt=dict(name="Cetirizina", exp="2027-06-30", qty=10)),
    dict(id="h2-captopril-venc", brand="Captopril", dose="25 mg", qty_text="30 comprimidos",
         exp_text="VENC 04/27   LOTE 7A21", dots=True, exp_at=(700, 560), bg="white", ink="#263238",
         band="#37474f", persp=0.09, glare=(0.7, 0.6, 0.1),
         gt=dict(name="Captopril", exp="2027-04-30", qty=30)),
    dict(id="h3-metformina-validade", brand="Metformina", generic="Cloridrato de metformina",
         dose="850 mg", qty_text="30 comprimidos", exp_text="Validade: 10/2026", bg="#e3f2fd",
         ink="#0d47a1", band="#1565c0", persp=0.05, noise=10,
         gt=dict(name="Metformina", exp="2026-10-31", qty=30)),
    dict(id="h4-dexclorfeniramina-frasco", brand="Dexclorfeniramina", brand_size=90, dose="2 mg/5 mL",
         qty_text="Frasco com 120 mL", exp_text="VAL 07/27 L 99Z1", dots=True, exp_rotate=-90,
         exp_at=(1250, 220), bg="#fce4ec", ink="#880e4f", band="#ad1457", persp=0.07,
         gt=dict(name="Dexclorfeniramina", exp="2027-07-31", qty=None)),
    dict(id="h5-azitromicina-reflexo", brand="Azitromicina", dose="500 mg",
         qty_text="3 comprimidos revestidos", exp_text="VAL. 01/2027", bg="white", ink="#1a237e",
         band="#283593", glare=(0.55, 0.62, 0.14), persp=0.06,
         gt=dict(name="Azitromicina", exp="2027-01-31", qty=3)),
    dict(id="h6-diclofenaco-desfoque", brand="Diclofenaco Sódico", brand_size=100, dose="50 mg",
         qty_text="20 comprimidos", exp_text="FAB 02/2025  VAL 02/2027", bg="#fff8e1", ink="#3e2723",
         band="#6d4c41", blur=2.6, persp=0.05,
         gt=dict(name="Diclofenaco Sódico", exp="2027-02-28", qty=20)),
    dict(id="h7-vitamina-c-escura", brand="Vitamina C", dose="1 g", qty_text="10 comprimidos efervescentes",
         exp_text="VAL 03/2027", dots=True, exp_at=(720, 560), bg="#fff3e0", ink="#e65100", band="#ef6c00",
         light=0.5, noise=16, persp=0.06, gt=dict(name="Vitamina C", exp="2027-03-31", qty=10)),
    dict(id="h8-nimesulida-inclinada", brand="Nimesulida", dose="100 mg", qty_text="12 comprimidos",
         exp_text="VAL: 08/2027", bg="white", ink="#004d40", band="#00796b", persp=0.14, rotate=18,
         gt=dict(name="Nimesulida", exp="2027-08-31", qty=12)),
]  # fmt: skip

CONJUNTOS = {"ajuste": (AJUSTE, 11), "validacao": (VALIDACAO, 23)}


class Generator:
    def __init__(self, fonts: Path, seed: int) -> None:
        self.fonts = fonts
        self.random = random.Random(seed)
        self.numpy = np.random.default_rng(seed)

    def font(self, name: str, size: int) -> ImageFont.FreeTypeFont:
        return ImageFont.truetype(str(self.fonts / name), size)

    def dot_matrix(self, text: str, size: int, step: int = 4, dot: float = 1.6) -> Image.Image:
        """Texto impresso em pontinhos, como a validade nas abas."""
        font = self.font("consola.ttf", size)
        box = font.getbbox(text)
        width, height = box[2] + 8, box[3] + 8
        mask = Image.new("L", (width, height), 0)
        ImageDraw.Draw(mask).text((4, 4), text, fill=255, font=font)
        pixels = np.array(mask)
        out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(out)
        for y in range(0, height, step):
            for x in range(0, width, step):
                if pixels[y, x] > 110:
                    jx = self.random.uniform(-0.4, 0.4)
                    jy = self.random.uniform(-0.4, 0.4)
                    draw.ellipse(
                        (x - dot + jx, y - dot + jy, x + dot + jx, y + dot + jy),
                        fill=(30, 30, 30, 235),
                    )
        return out

    def package(self, spec: dict[str, Any]) -> Image.Image:
        width, height = 1400, 900
        image = Image.new("RGB", (width, height), spec["bg"])
        draw = ImageDraw.Draw(image)
        draw.rectangle((0, 0, width, 170), fill=spec["band"])
        draw.text((60, 45), "LABORATÓRIO EXEMPLO", fill="white", font=self.font("arialbd.ttf", 56))
        y = 230
        brand_size = spec.get("brand_size", 120)
        draw.text(
            (60, y), spec["brand"], fill=spec["ink"], font=self.font("arialbd.ttf", brand_size)
        )
        y += int(brand_size * 1.25)
        if spec.get("generic"):
            draw.text((60, y), spec["generic"], fill=spec["ink"], font=self.font("arial.ttf", 52))
            y += 80
        draw.text((60, y), spec["dose"], fill=spec["ink"], font=self.font("arialbd.ttf", 64))
        y += 100
        draw.text((60, y), spec["qty_text"], fill=spec["ink"], font=self.font("arial.ttf", 46))
        draw.text(
            (60, height - 90),
            "VENDA SOB PRESCRIÇÃO MÉDICA",
            fill=spec["ink"],
            font=self.font("arial.ttf", 34),
        )
        draw.rectangle((0, height - 30, width, height), fill="#c62828")
        text = spec["exp_text"]
        if spec.get("dots"):
            stamp = self.dot_matrix(text, spec.get("exp_size", 44))
        else:
            font = self.font("arial.ttf", spec.get("exp_size", 38))
            box = font.getbbox(text)
            stamp = Image.new("RGBA", (box[2] + 10, box[3] + 10), (0, 0, 0, 0))
            ImageDraw.Draw(stamp).text((5, 5), text, fill=(25, 25, 25, 255), font=font)
        if spec.get("exp_rotate"):
            stamp = stamp.rotate(spec["exp_rotate"], expand=True)
        image.paste(stamp, spec.get("exp_at", (760, 520)), stamp)
        return image

    def photograph(self, image: Image.Image, spec: dict[str, Any]) -> bytes:
        array = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        height, width = array.shape[:2]
        k = spec.get("persp", 0.06)

        def jitter() -> float:
            return self.random.uniform(0, k)

        source = np.float32([[0, 0], [width, 0], [width, height], [0, height]])
        target = np.float32(
            [
                [width * jitter(), height * jitter()],
                [width * (1 - jitter()), height * jitter()],
                [width * (1 - jitter()), height * (1 - jitter())],
                [width * jitter(), height * (1 - jitter())],
            ]
        )
        pad = 160
        canvas_w, canvas_h = width + 2 * pad, height + 2 * pad
        table_color = (150, 160, 170)
        table = np.full((canvas_h, canvas_w, 3), table_color, np.uint8)
        matrix = cv2.getPerspectiveTransform(source, target + pad)
        warped = cv2.warpPerspective(
            array, matrix, (canvas_w, canvas_h), dst=table, borderMode=cv2.BORDER_TRANSPARENT
        )
        angle = spec.get("rotate", self.random.uniform(-6, 6))
        rotation = cv2.getRotationMatrix2D((canvas_w / 2, canvas_h / 2), angle, 1)
        warped = cv2.warpAffine(warped, rotation, (canvas_w, canvas_h), borderValue=table_color)
        out = warped.astype(np.float32)
        yy, xx = np.mgrid[0:canvas_h, 0:canvas_w]
        light = spec.get("light", 1.0) * (0.85 + 0.25 * (xx / canvas_w))
        out *= light[..., None]
        if spec.get("glare"):
            gx, gy, radius = spec["glare"]
            spot = np.exp(
                -(
                    ((xx - gx * canvas_w) ** 2 + (yy - gy * canvas_h) ** 2)
                    / (2 * (radius * canvas_w) ** 2)
                )
            )
            out = out + spot[..., None] * 170
        out += self.numpy.normal(0, spec.get("noise", 6), out.shape)
        out = np.clip(out, 0, 255).astype(np.uint8)
        if spec.get("blur"):
            out = cv2.GaussianBlur(out, (0, 0), spec["blur"])
        out = cv2.resize(out, None, fx=0.75, fy=0.75, interpolation=cv2.INTER_AREA)
        ok, buffer = cv2.imencode(".jpg", out, [cv2.IMWRITE_JPEG_QUALITY, 80])
        if not ok:
            raise RuntimeError("falha ao gerar JPEG")
        return buffer.tobytes()


def generate(conjunto: str, fonts: Path) -> Path:
    specs, seed = CONJUNTOS[conjunto]
    folder = OUTPUT_DIR / conjunto
    folder.mkdir(parents=True, exist_ok=True)
    generator = Generator(fonts, seed)
    truth = {}
    for spec in specs:
        (folder / f"{spec['id']}.jpg").write_bytes(
            generator.photograph(generator.package(spec), spec)
        )
        truth[spec["id"]] = spec["gt"]
    (folder / "gabarito.json").write_text(json.dumps(truth, ensure_ascii=False, indent=2), "utf-8")
    return folder


def _plain(text: str | None) -> str:
    normalized = unicodedata.normalize("NFKD", (text or "").upper())
    return "".join(char for char in normalized if not unicodedata.combining(char)).strip()


def measure(conjunto: str, api: str) -> None:
    folder = OUTPUT_DIR / conjunto
    truth = json.loads((folder / "gabarito.json").read_text("utf-8"))
    env = dict(
        line.split("=", 1)
        for line in (BACKEND_DIR / ".env").read_text("utf-8").splitlines()
        if "=" in line and not line.startswith("#")
    )
    totals = {"nome": 0, "validade": 0, "quantidade": 0}
    with httpx.Client(base_url=api, timeout=120) as client:
        login = client.post(
            "/v1/auth/login",
            json={"email": env["ZELO_DEMO_EMAIL"], "password": env["ZELO_DEMO_PASSWORD"]},
        )
        login.raise_for_status()
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        for key, expected in truth.items():
            started = time.perf_counter()
            response = client.post(
                "/v1/ocr/medication",
                headers=headers,
                files={"image": (f"{key}.jpg", (folder / f"{key}.jpg").read_bytes(), "image/jpeg")},
            )
            elapsed = (time.perf_counter() - started) * 1000
            result = response.json()
            names = [_plain(name) for name in result.get("name_candidates") or []]
            hits = {
                "nome": bool(names) and _plain(expected["name"]) in names[0],
                "validade": result.get("expiration_date") == expected["exp"],
                "quantidade": result.get("quantity") == expected["qty"],
            }
            for field, ok in hits.items():
                totals[field] += ok
            marks = "  ".join(f"{field} {'ok' if ok else '--'}" for field, ok in hits.items())
            print(f"{key:30s} {marks}  {elapsed:6.0f} ms")
    total = len(truth)
    print(" | ".join(f"{field} {hits}/{total}" for field, hits in totals.items()))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("acao", choices=["gerar", "medir"])
    parser.add_argument("--conjunto", choices=sorted(CONJUNTOS), default="validacao")
    parser.add_argument("--api", default="http://localhost:8000")
    parser.add_argument("--fontes", type=Path, default=Path(r"C:\Windows\Fonts"))
    args = parser.parse_args()
    if args.acao == "gerar":
        print("amostras em", generate(args.conjunto, args.fontes))
    else:
        measure(args.conjunto, args.api)
    return 0


if __name__ == "__main__":
    sys.exit(main())
