FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Leitura de embalagens (OCR): RapidOCR (PP-OCR em ONNX) é o motor principal;
# o Tesseract em português fica como reserva. libgl1 e libglib2.0-0 são
# exigidos pelo OpenCV usado pelo RapidOCR.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tesseract-ocr tesseract-ocr-por libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Os modelos do PP-OCR são baixados no build: a API não depende de internet.
RUN pip install -r requirements.txt \
    && python -c "from rapidocr import RapidOCR; RapidOCR(params={'Global.log_level': 'error'})"

COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
COPY scripts ./scripts

RUN useradd --create-home --uid 10001 zelo && chown -R zelo /app
USER zelo

EXPOSE 8000

# Aplica as migrações e inicia a API.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000"]
