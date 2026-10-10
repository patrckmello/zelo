import io
from datetime import date

from PIL import Image

from app.services.medication_ocr import (
    FallbackRecognizer,
    OcrLine,
    OcrUnavailableError,
    RapidOcrRecognizer,
    TesseractRecognizer,
    default_recognizer,
    parse_medication_text,
    scan_package,
)

from .conftest import auth_headers, register

SCAN = "/v1/ocr/medication"


def lines(*items):
    return [OcrLine(text, height) if isinstance(text, str) else text for text, height in items]


def png(width=320, height=200) -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (width, height), "white").save(buffer, format="PNG")
    return buffer.getvalue()


# ------------------------------------------------------------- interpretação


def test_embalagem_tipica_com_fabricacao_validade_e_quantidade():
    scan = parse_medication_text(
        lines(
            ("DIPIRONA MONOIDRATADA", 64),
            ("500 mg", 40),
            ("Contém 20 comprimidos", 18),
            ("FAB: 03/2025  VAL: 03/2027", 14),
            ("LOTE: ABC123", 14),
            ("VENDA SOB PRESCRIÇÃO MÉDICA", 12),
        )
    )
    assert scan.name_candidates[0] == "Dipirona Monoidratada"
    assert scan.expiration_date == date(2027, 3, 31)
    assert scan.expiration_text == "03/2027"
    assert scan.expiration_has_day is False
    assert scan.quantity == 20


def test_data_completa_mes_por_extenso_e_confusoes_de_ocr():
    assert parse_medication_text(lines(("VAL.: 15/08/27", 10))).expiration_date == date(2027, 8, 15)
    assert parse_medication_text(lines(("VAL. AGO/2027", 10))).expiration_date == date(2027, 8, 31)
    assert parse_medication_text(lines(("VAL: O3/2O27", 10))).expiration_date == date(2027, 3, 31)
    assert parse_medication_text(lines(("Validade 05 2027", 10))).expiration_date == date(
        2027, 5, 31
    )


def test_rotulo_na_linha_anterior():
    scan = parse_medication_text(lines(("VALIDADE", 10), ("11/2026", 10)))
    assert scan.expiration_date == date(2026, 11, 30)


def test_sem_rotulo_usa_a_data_mais_distante_e_ignora_fabricacao():
    assert parse_medication_text(lines(("03/2025", 10), ("03/2027", 10))).expiration_date == (
        date(2027, 3, 31)
    )
    only_manufacture = parse_medication_text(lines(("FAB 01/2026", 10)))
    assert only_manufacture.expiration_date is None


def test_rejeita_datas_impossiveis_e_falsos_positivos():
    assert parse_medication_text(lines(("VAL 13/2027", 10))).expiration_date is None
    assert parse_medication_text(lines(("LOTE IS/ID", 10))).expiration_date is None
    assert parse_medication_text(lines(("VAL 03/1999", 10))).expiration_date is None


def test_nomes_ignoram_avisos_e_repeticoes():
    scan = parse_medication_text(
        lines(
            ("Loratadina", 50),
            ("LORATADINA", 48),
            ("Uso adulto e pediátrico", 30),
            ("Mantenha fora do alcance das crianças", 30),
            ("Xarope", 26),
            ("10 mg", 40),
        )
    )
    assert scan.name_candidates == ["Loratadina", "Xarope"]


def test_rotulo_grudado_na_data_e_lote_em_seguida():
    scan = parse_medication_text(lines(("FAB 01/25", 12), ("VAL01/28L2231", 12)))
    assert scan.expiration_date == date(2028, 1, 31)
    assert scan.expiration_text == "01/28"


def test_nome_do_laboratorio_nao_vira_opcao_de_nome():
    scan = parse_medication_text(
        lines(("LABORATÓRIO EXEMPLO", 70), ("Paracetamol", 60), ("Farmacêutica Exemplo Ltda", 40))
    )
    assert scan.name_candidates == ["Paracetamol"]


class _OrientationRecognizer:
    """Só "vê" a validade quando a imagem fica em pé, como a aba girada."""

    def __init__(self) -> None:
        self.calls = 0

    def recognize(self, image):
        self.calls += 1
        if image.height > image.width:
            return [OcrLine("VAL 02/2027", 20), OcrLine("ruído", 20)]
        return [OcrLine("Simeticona", 60), OcrLine("Frasco com 15 mL", 20)]


def test_rotulo_grudado_no_ano_anterior():
    scan = parse_medication_text(lines(("FAB 02/2025VAL 02/2027", 14)))
    assert scan.expiration_date == date(2027, 2, 28)


def test_sem_validade_tenta_desfoque_e_depois_a_imagem_girada():
    recognizer = _OrientationRecognizer()
    scan, passes = scan_package(recognizer, Image.new("RGB", (300, 200)))
    assert scan.expiration_date == date(2027, 2, 28)
    assert scan.name_candidates[0] == "Simeticona"
    # Original, desfocada (ainda deitada) e girada 90°.
    assert passes == 3


def test_com_validade_na_primeira_leitura_nao_gira():
    recognizer = _OrientationRecognizer()
    scan, passes = scan_package(recognizer, Image.new("RGB", (200, 300)))
    assert scan.expiration_date == date(2027, 2, 28)
    assert passes == 1
    assert recognizer.calls == 1


def test_sem_validade_em_nenhuma_variacao_faz_seis_leituras():
    class Blind:
        def recognize(self, image):
            return [OcrLine("Simeticona", 60)]

    scan, passes = scan_package(Blind(), Image.new("RGB", (300, 200)))
    assert scan.expiration_date is None
    assert scan.name_candidates == ["Simeticona"]
    assert passes == 6


def test_motor_padrao_tem_reserva_e_pode_ser_escolhido():
    assert isinstance(default_recognizer("tesseract"), TesseractRecognizer)
    padrao = default_recognizer()
    assert isinstance(padrao, FallbackRecognizer)
    assert [type(item) for item in padrao.recognizers] == [RapidOcrRecognizer, TesseractRecognizer]


def test_reserva_usa_o_proximo_motor_quando_o_primeiro_falta():
    class Missing:
        available = True

        def recognize(self, image):
            raise OcrUnavailableError

    class Working:
        available = True

        def recognize(self, image):
            return [OcrLine("Dipirona", 40)]

    class Off:
        available = False

    recognizer = FallbackRecognizer(Off(), Missing(), Working())
    assert recognizer.recognize(Image.new("RGB", (10, 10)))[0].text == "Dipirona"
    assert recognizer.available is True
    assert FallbackRecognizer(Off()).available is False


# ------------------------------------------------------------- rota


def test_rota_devolve_a_leitura_sem_guardar_dados(client, recognizer):
    headers = auth_headers(register(client))
    recognizer.lines = lines(("PARACETAMOL", 60), ("VAL 09/2027", 12))

    response = client.post(
        SCAN, files={"image": ("caixa.png", png(), "image/png")}, headers=headers
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["name_candidates"] == ["Paracetamol"]
    assert body["expiration_date"] == "2027-09-30"
    assert body["expiration_has_day"] is False
    assert "PARACETAMOL" in body["text"]


def test_rota_exige_autenticacao_e_valida_o_arquivo(client, recognizer):
    assert client.post(SCAN, files={"image": ("x.png", png(), "image/png")}).status_code == 401
    headers = auth_headers(register(client))

    pdf = client.post(
        SCAN, files={"image": ("bula.pdf", b"%PDF-1.4", "application/pdf")}, headers=headers
    )
    broken = client.post(
        SCAN, files={"image": ("x.jpg", b"nao e imagem", "image/jpeg")}, headers=headers
    )
    huge = client.post(
        SCAN,
        files={"image": ("x.png", b"0" * (8 * 1024 * 1024 + 1), "image/png")},
        headers=headers,
    )

    assert pdf.status_code == 415
    assert broken.status_code == 422
    assert huge.status_code == 413
    assert recognizer.calls == 0


def test_rota_informa_ocr_indisponivel_e_limita_leituras(client, recognizer):
    headers = auth_headers(register(client))
    recognizer.available = False
    unavailable = client.post(SCAN, files={"image": ("x.png", png(), "image/png")}, headers=headers)
    assert unavailable.status_code == 503
    assert unavailable.json()["error"]["code"] == "ocr_unavailable"

    recognizer.available = True
    statuses = [
        client.post(
            SCAN, files={"image": ("x.png", png(), "image/png")}, headers=headers
        ).status_code
        for _ in range(20)
    ]
    assert statuses[-1] == 429
