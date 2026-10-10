"""Verificação de saúde para Docker e diagnóstico local."""

from fastapi import APIRouter
from fastapi.responses import JSONResponse
from sqlalchemy import text

from ..dependencies import ContainerDep

router = APIRouter(tags=["saúde"])


@router.get("/health")
def health(container: ContainerDep) -> JSONResponse:
    try:
        with container.database.engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        database = "ok"
    except Exception:  # noqa: BLE001 - qualquer falha torna o serviço indisponível
        database = "indisponivel"
    healthy = database == "ok"
    return JSONResponse(
        status_code=200 if healthy else 503,
        content={
            "status": "ok" if healthy else "degradado",
            "database": database,
            "ecomed_configured": container.collection_points.configured,
            "ocr_available": getattr(container.text_recognizer, "available", True),
        },
    )
