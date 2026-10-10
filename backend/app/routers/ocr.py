"""Leitura de embalagem por foto (OCR assistido, sempre confirmado pela pessoa)."""

import logging

from fastapi import APIRouter, UploadFile
from starlette.concurrency import run_in_threadpool

from ..dependencies import ContainerDep, CurrentUser
from ..errors import ApiError
from ..schemas import MedicationScanOut
from ..services.medication_ocr import (
    ACCEPTED_TYPES,
    MAX_IMAGE_BYTES,
    InvalidImageError,
    OcrUnavailableError,
    prepare_image,
    scan_package,
)

router = APIRouter(prefix="/ocr", tags=["leitura de embalagem"])
logger = logging.getLogger("zelo.ocr")


@router.post("/medication", response_model=MedicationScanOut)
async def scan_medication(
    image: UploadFile, user: CurrentUser, container: ContainerDep
) -> MedicationScanOut:
    wait = container.ocr_limiter.try_acquire(str(user.id))
    if wait is not None:
        raise ApiError(
            429,
            "too_many_scans",
            "Muitas leituras seguidas. Aguarde um instante.",
            headers={"Retry-After": str(max(int(wait), 1))},
        )
    if image.content_type not in ACCEPTED_TYPES:
        raise ApiError(415, "unsupported_image", "Envie uma foto em JPG, PNG ou WebP.")
    data = await image.read(MAX_IMAGE_BYTES + 1)
    if len(data) > MAX_IMAGE_BYTES:
        raise ApiError(413, "image_too_large", "A foto deve ter no máximo 8 MB.")

    try:
        prepared = await run_in_threadpool(prepare_image, data)
        scan, passes = await run_in_threadpool(scan_package, container.text_recognizer, prepared)
    except InvalidImageError:
        raise ApiError(422, "invalid_image", "Não foi possível abrir esta imagem.") from None
    except OcrUnavailableError:
        raise ApiError(
            503, "ocr_unavailable", "A leitura de embalagens não está disponível no servidor."
        ) from None
    finally:
        del data

    # Somente o resultado agregado vai para o log, nunca o texto lido.
    logger.info(
        "ocr_leitura motor=%s leituras=%d linhas=%d nomes=%d validade=%s quantidade=%s",
        getattr(container.text_recognizer, "name", type(container.text_recognizer).__name__),
        passes,
        scan.text.count("\n") + 1 if scan.text else 0,
        len(scan.name_candidates),
        "sim" if scan.expiration_date else "nao",
        "sim" if scan.quantity else "nao",
    )
    return MedicationScanOut(
        name_candidates=scan.name_candidates,
        expiration_date=scan.expiration_date,
        expiration_text=scan.expiration_text,
        expiration_has_day=scan.expiration_has_day,
        quantity=scan.quantity,
        text=scan.text,
    )
