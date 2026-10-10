"""Leitura assistida de embalagens de medicamento (OCR).

A imagem é processada em memória e descartada: nada é gravado em disco, banco
ou logs. O resultado é uma sugestão; a pessoa sempre confere e confirma os
campos antes de salvar (D004).
"""

import calendar
import importlib.util
import io
import logging
import re
import shutil
import subprocess
import threading
import unicodedata
from collections.abc import Iterator
from dataclasses import dataclass, field, replace
from datetime import date
from statistics import median
from typing import Protocol

from PIL import Image, ImageFilter, ImageOps, UnidentifiedImageError

logger = logging.getLogger("zelo.ocr")

MAX_IMAGE_BYTES = 8 * 1024 * 1024
MAX_IMAGE_PIXELS = 40_000_000
ACCEPTED_TYPES = {"image/jpeg", "image/png", "image/webp"}

_MONTHS = {
    "JAN": 1, "FEV": 2, "FEB": 2, "MAR": 3, "ABR": 4, "APR": 4, "MAI": 5,
    "MAY": 5, "JUN": 6, "JUL": 7, "AGO": 8, "AUG": 8, "SET": 9, "SEP": 9,
    "OUT": 10, "OCT": 10, "NOV": 11, "DEZ": 12, "DEC": 12,
}  # fmt: skip
_EXPIRATION_LABEL = re.compile(r"\b(VAL(IDADE)?|VENC(IMENTO)?|VCTO|EXP(IRA\w*)?|VALID)\b\.?")
_MANUFACTURE_LABEL = re.compile(r"\b(FAB(R)?(ICA[CÇ][AÃ]O)?|MFG|FABRICADO)\b\.?")
_DIGITISH = "0-9OQDIL|SBZ"
_DATE_TOKEN = re.compile(
    rf"(?<![0-9A-Z])([{_DIGITISH}]{{1,2}})\s?[/.\-]\s?([{_DIGITISH}]{{1,2}})\s?[/.\-]\s?"
    rf"([{_DIGITISH}]{{4}}|[{_DIGITISH}]{{2}})(?![0-9])"
    rf"|(?<![0-9A-Z/])([{_DIGITISH}]{{1,2}})\s?[/.\-]\s?([{_DIGITISH}]{{4}}|[{_DIGITISH}]{{2}})(?![0-9/])"
    rf"|\b({'|'.join(_MONTHS)})\s?[/.\-]?\s?([{_DIGITISH}]{{4}}|[{_DIGITISH}]{{2}})(?![0-9])"
)
_LABELED_SPACED = re.compile(r"([0-9]{1,2})\s+([0-9]{4})\b")
# "VAL01/28": rótulo grudado na data, comum em impressão por jato de tinta.
_GLUED_LABEL = re.compile(
    r"\b(VAL(?:IDADE)?|VENC(?:IMENTO)?|VCTO|FAB|EXP)(?=[0-9OQDILSBZ]{1,2}\s?[/.\-])"
)
# "02/2025VAL 02/2027": rótulo grudado no ano anterior.
_LABEL_AFTER_DIGIT = re.compile(r"(?<=[0-9])(?=(?:VAL|VENC|VCTO|FAB|EXP|LOTE)\b)")
_QUANTITY = re.compile(
    r"\b(\d{1,4})\s*(COMPRIMIDOS?|COMP\.?|CAPSULAS?|CAPS\.?|DRAGEAS?|SACHES?|"
    r"ENVELOPES?|AMPOLAS?|FRASCOS?|UNIDADES?|ADESIVOS?|TABLETES?|SUPOSITORIOS?)\b"
)
_NAME_STOPWORDS = re.compile(
    r"\b(VAL|VALIDADE|VENC|LOTE|FAB|FABRICACAO|VENDA|PRESCRICAO|RECEITA|USO|ADULTO|"
    r"PEDIATRICO|ORAL|CONTEM|REG|MS|FARM|RESP|SAC|LEI|GENERICO|MEDICAMENTO|"
    r"INDUSTRIA|CNPJ|WWW|ATENCAO|MANTENHA|INFORMACOES|COMPRIMIDOS?|CAPSULAS?|"
    r"EMBALAGEM|CONSERVAR|TEMPERATURA|CRIANCAS|ALCANCE|BULA|SIGA|ORIENTACAO|"
    r"DRAGEAS?|REVESTIDOS?|SOLUCAO|SUSPENSAO|XAROPE\s+INFANTIL|LABORATORIOS?|"
    r"FARMACEUTICA|LTDA|FRASCOS?)\b"
)
_TRANSLATE_DIGITS = str.maketrans({"O": "0", "Q": "0", "D": "0", "I": "1", "L": "1",
                                   "|": "1", "S": "5", "B": "8", "Z": "2"})  # fmt: skip


class OcrUnavailableError(Exception):
    """O mecanismo de OCR não está instalado neste ambiente."""


class InvalidImageError(Exception):
    """O arquivo enviado não é uma imagem utilizável."""


@dataclass(frozen=True)
class OcrLine:
    text: str
    height: float = 0.0


@dataclass
class MedicationScan:
    name_candidates: list[str] = field(default_factory=list)
    expiration_date: date | None = None
    expiration_text: str | None = None
    expiration_has_day: bool = False
    quantity: int | None = None
    text: str = ""


class TextRecognizer(Protocol):
    def recognize(self, image: Image.Image) -> list[OcrLine]: ...


def prepare_image(data: bytes) -> Image.Image:
    """Abre, corrige a orientação e normaliza tamanho e contraste."""
    if len(data) > MAX_IMAGE_BYTES:
        raise InvalidImageError("too_large")
    Image.MAX_IMAGE_PIXELS = MAX_IMAGE_PIXELS
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as error:
        raise InvalidImageError("invalid") from error
    image = ImageOps.exif_transpose(image).convert("L")
    longest = max(image.size)
    target = min(max(longest, 1600), 2400)
    if longest != target:
        scale = target / longest
        image = image.resize(
            (max(int(image.width * scale), 1), max(int(image.height * scale), 1)),
            Image.Resampling.LANCZOS,
        )
    return ImageOps.autocontrast(image, cutoff=1)


class TesseractRecognizer:
    """Tesseract em português, modo de texto esparso (rótulos e embalagens)."""

    def __init__(self, executable: str | None = None, timeout_seconds: float = 25) -> None:
        self.executable = executable or shutil.which("tesseract")
        self.timeout_seconds = timeout_seconds

    @property
    def available(self) -> bool:
        return self.executable is not None

    def recognize(self, image: Image.Image) -> list[OcrLine]:
        if self.executable is None:
            raise OcrUnavailableError
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        lines: list[OcrLine] = []
        for psm in ("11", "6"):
            result = subprocess.run(  # noqa: S603 - executável e argumentos fixos
                [self.executable, "stdin", "stdout", "-l", "por", "--psm", psm, "tsv"],
                input=buffer.getvalue(),
                capture_output=True,
                timeout=self.timeout_seconds,
                check=False,
            )
            if result.returncode != 0:
                logger.warning("ocr_falhou psm=%s codigo=%d", psm, result.returncode)
                continue
            lines.extend(_parse_tsv(result.stdout.decode("utf-8", errors="replace")))
        return lines


class RapidOcrRecognizer:
    """PP-OCR (PaddleOCR) via RapidOCR e ONNX Runtime, só CPU.

    Detecta linhas em qualquer ângulo e lê bem fotos com perspectiva, reflexo e
    validade em pontinhos, onde o Tesseract falha. Os modelos ficam embutidos
    na imagem Docker; o motor é carregado na primeira leitura.
    """

    def __init__(self, min_confidence: float = 0.5) -> None:
        self.min_confidence = min_confidence
        self._engine = None
        self._lock = threading.Lock()

    @property
    def available(self) -> bool:
        return all(
            importlib.util.find_spec(module) is not None for module in ("rapidocr", "onnxruntime")
        )

    def recognize(self, image: Image.Image) -> list[OcrLine]:
        try:
            import numpy as np
            from rapidocr import RapidOCR
        except ImportError as error:
            raise OcrUnavailableError from error
        # Uma leitura por vez: o motor ocupa CPU e memória.
        with self._lock:
            if self._engine is None:
                self._engine = RapidOCR(params={"Global.log_level": "error"})
            result = self._engine(np.asarray(image.convert("RGB")))
        lines: list[OcrLine] = []
        if result.boxes is None:
            return lines
        for box, text, score in zip(result.boxes, result.txts, result.scores, strict=False):
            if score < self.min_confidence or not text.strip():
                continue
            corners = np.asarray(box, dtype=float)
            # Altura da linha: o menor lado da caixa (vale para texto girado).
            height = min(
                np.linalg.norm(corners[0] - corners[3]), np.linalg.norm(corners[0] - corners[1])
            )
            lines.append(OcrLine(text.strip(), float(height)))
        return lines


class FallbackRecognizer:
    """Usa o primeiro motor disponível; se ele faltar, tenta o seguinte."""

    def __init__(self, *recognizers: TextRecognizer) -> None:
        self.recognizers = recognizers

    @property
    def available(self) -> bool:
        return any(getattr(item, "available", True) for item in self.recognizers)

    @property
    def name(self) -> str:
        for item in self.recognizers:
            if getattr(item, "available", True):
                return type(item).__name__
        return "nenhum"

    def recognize(self, image: Image.Image) -> list[OcrLine]:
        for item in self.recognizers:
            if not getattr(item, "available", True):
                continue
            try:
                return item.recognize(image)
            except OcrUnavailableError:
                continue
        raise OcrUnavailableError


def default_recognizer(engine: str = "rapidocr") -> TextRecognizer:
    if engine == "tesseract":
        return TesseractRecognizer()
    return FallbackRecognizer(RapidOcrRecognizer(), TesseractRecognizer())


def _retry_variants(image: Image.Image) -> Iterator[Image.Image]:
    """Novas tentativas quando a validade não aparece, da mais barata para a
    mais cara. O desfoque leve une os pontinhos da impressão por jato de tinta;
    os giros pegam a validade impressa na aba, na vertical."""
    blurred = image.filter(ImageFilter.GaussianBlur(2))
    yield blurred
    for angle in (90, 270):
        yield image.rotate(angle, expand=True)
    for angle in (90, 270):
        yield blurred.rotate(angle, expand=True)


def scan_package(recognizer: TextRecognizer, image: Image.Image) -> tuple[MedicationScan, int]:
    """Lê a embalagem e, se a validade não aparecer, tenta variações da foto
    até encontrá-la. Devolve o resultado e o número de leituras feitas."""
    lines = recognizer.recognize(image)
    scan = parse_medication_text(lines)
    passes = 1
    if scan.expiration_date is not None:
        return scan, passes
    for variant in _retry_variants(image):
        lines = lines + recognizer.recognize(variant)
        passes += 1
        retried = parse_medication_text(lines)
        if retried.expiration_date is not None:
            # Nome e quantidade vêm da leitura da foto original.
            return replace(
                retried,
                name_candidates=scan.name_candidates or retried.name_candidates,
                quantity=scan.quantity if scan.quantity is not None else retried.quantity,
            ), passes
    return scan, passes


def _parse_tsv(tsv: str) -> list[OcrLine]:
    groups: dict[tuple[str, str, str], list[tuple[str, float]]] = {}
    for row in tsv.splitlines()[1:]:
        columns = row.split("\t")
        if len(columns) < 12 or columns[0] != "5":
            continue
        word = columns[11].strip()
        try:
            confidence = float(columns[10])
            height = float(columns[9])
        except ValueError:
            continue
        if not word or confidence < 0:
            continue
        groups.setdefault((columns[2], columns[3], columns[4]), []).append((word, height))
    return [
        OcrLine(" ".join(word for word, _ in words), median(h for _, h in words))
        for words in groups.values()
    ]


def _plain(text: str) -> str:
    """Maiúsculas sem acentos, para comparar rótulos."""
    normalized = unicodedata.normalize("NFKD", text.upper())
    return "".join(char for char in normalized if not unicodedata.combining(char))


def _year(raw: str) -> int | None:
    value = int(raw)
    if len(raw) == 2:
        value += 2000
    return value if 2000 <= value <= 2100 else None


def _build_date(day: int | None, month: int, year: int | None) -> date | None:
    if year is None or not 1 <= month <= 12:
        return None
    last_day = calendar.monthrange(year, month)[1]
    if day is None:
        # Sem o dia, a validade vale até o último dia do mês informado.
        return date(year, month, last_day)
    return date(year, month, day) if 1 <= day <= last_day else None


@dataclass
class _DateCandidate:
    value: date
    has_day: bool
    text: str
    kind: str  # "expiration", "manufacture" ou "unknown"


def _dates_in_line(line: str, previous: str) -> list[_DateCandidate]:
    plain = _GLUED_LABEL.sub(r"\1 ", _LABEL_AFTER_DIGIT.sub(" ", _plain(line)))
    candidates: list[_DateCandidate] = []
    for match in _DATE_TOKEN.finditer(plain):
        groups = match.groups()
        # Letras parecidas com números só valem junto de dígitos reais.
        if sum(char.isdigit() for char in match.group(0)) < (2 if groups[5] else 3):
            continue
        parsed: date | None = None
        has_day = False
        try:
            if groups[0] is not None:
                day = int(groups[0].translate(_TRANSLATE_DIGITS))
                month = int(groups[1].translate(_TRANSLATE_DIGITS))
                parsed = _build_date(day, month, _year(groups[2].translate(_TRANSLATE_DIGITS)))
                has_day = True
            elif groups[3] is not None:
                month = int(groups[3].translate(_TRANSLATE_DIGITS))
                parsed = _build_date(None, month, _year(groups[4].translate(_TRANSLATE_DIGITS)))
            else:
                parsed = _build_date(
                    None, _MONTHS[groups[5]], _year(groups[6].translate(_TRANSLATE_DIGITS))
                )
        except ValueError:
            continue
        if parsed is None:
            continue
        candidates.append(
            _DateCandidate(parsed, has_day, plain[match.start() : match.end()].strip(), "unknown")
        )

    if not candidates and _EXPIRATION_LABEL.search(plain):
        # "VAL 03 2027": mês e ano separados só por espaço após o rótulo.
        for match in _LABELED_SPACED.finditer(plain):
            parsed = _build_date(None, int(match.group(1)), _year(match.group(2)))
            if parsed is not None:
                candidates.append(_DateCandidate(parsed, False, match.group(0), "unknown"))

    for candidate in candidates:
        position = plain.find(_plain(candidate.text))
        before = plain[max(position - 16, 0) : position] if position >= 0 else ""
        context = before if before.strip() else _plain(previous)[-16:]
        labels = list(_EXPIRATION_LABEL.finditer(context)) + list(
            _MANUFACTURE_LABEL.finditer(context)
        )
        if labels:
            nearest = max(labels, key=lambda label: label.end())
            candidate.kind = (
                "expiration" if _EXPIRATION_LABEL.fullmatch(nearest.group(0)) else "manufacture"
            )
    return candidates


def _choose_expiration(candidates: list[_DateCandidate]) -> _DateCandidate | None:
    labeled = [c for c in candidates if c.kind == "expiration"]
    if labeled:
        return max(labeled, key=lambda c: c.value)
    manufactured = [c.value for c in candidates if c.kind == "manufacture"]
    unknown = [
        c for c in candidates if c.kind == "unknown" and all(c.value > m for m in manufactured)
    ]
    # Sem rótulo, a validade é a data mais distante (a fabricação vem antes).
    return max(unknown, key=lambda c: c.value) if unknown else None


def _display_name(text: str) -> str:
    words = text.split()
    if text.upper() != text:
        return text
    return " ".join(word if len(word) <= 3 else word.capitalize() for word in words)


def _name_candidates(lines: list[OcrLine]) -> list[str]:
    scored: list[tuple[float, str]] = []
    for line in lines:
        cleaned = re.sub(r"[^\wÀ-ÿ\s\-+,.%]", " ", line.text)
        cleaned = " ".join(cleaned.split()).strip(" .,-")
        plain = _plain(cleaned)
        letters = sum(char.isalpha() for char in cleaned)
        if letters < 4 or len(cleaned) > 48 or _NAME_STOPWORDS.search(plain):
            continue
        if not re.search(r"[A-Za-zÀ-ÿ]{4,}", cleaned):
            continue
        ratio = letters / max(len(cleaned.replace(" ", "")), 1)
        if ratio < 0.6:
            continue
        scored.append((line.height * ratio, _display_name(cleaned)))
    unique: list[str] = []
    for _, name in sorted(scored, key=lambda item: item[0], reverse=True):
        if all(_plain(name) != _plain(existing) for existing in unique):
            unique.append(name)
    return unique[:3]


def parse_medication_text(lines: list[OcrLine]) -> MedicationScan:
    candidates: list[_DateCandidate] = []
    previous = ""
    for line in lines:
        candidates.extend(_dates_in_line(line.text, previous))
        previous = line.text
    chosen = _choose_expiration(candidates)

    quantity = None
    joined = "\n".join(line.text for line in lines)
    if match := _QUANTITY.search(_plain(joined)):
        quantity = int(match.group(1)) or None

    return MedicationScan(
        name_candidates=_name_candidates(lines),
        expiration_date=chosen.value if chosen else None,
        expiration_text=chosen.text if chosen else None,
        expiration_has_day=chosen.has_day if chosen else False,
        quantity=quantity,
        text=joined[:2000],
    )
