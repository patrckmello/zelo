"""Erros estáveis da API: código legível por máquina e mensagem segura.

Detalhes internos, exceções e dados enviados nunca são devolvidos ao cliente.
"""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("zelo.api")


class ApiError(Exception):
    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(code)
        self.status_code = status_code
        self.code = code
        self.message = message
        self.headers = headers


def _body(code: str, message: str, details: list | None = None) -> dict:
    error: dict = {"code": code, "message": message}
    if details:
        error["details"] = details
    return {"error": error}


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def _api_error(_request: Request, error: ApiError) -> JSONResponse:
        return JSONResponse(
            status_code=error.status_code,
            content=_body(error.code, error.message),
            headers=error.headers,
        )

    @app.exception_handler(RequestValidationError)
    async def _validation_error(_request: Request, error: RequestValidationError) -> JSONResponse:
        # Somente o caminho e o tipo do erro: valores enviados (senhas,
        # coordenadas, nomes de medicamentos) não são ecoados.
        details = [
            {
                "field": ".".join(str(part) for part in item.get("loc", ())[1:]),
                "type": item.get("type"),
            }
            for item in error.errors()
        ]
        return JSONResponse(
            status_code=422,
            content=_body("validation_error", "Revise os dados enviados.", details),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http_error(_request: Request, error: StarletteHTTPException) -> JSONResponse:
        code = {404: "not_found", 405: "method_not_allowed"}.get(error.status_code, "http_error")
        message = {404: "Recurso não encontrado.", 405: "Método não permitido."}.get(
            error.status_code, "Não foi possível processar a solicitação."
        )
        return JSONResponse(status_code=error.status_code, content=_body(code, message))

    @app.exception_handler(Exception)
    async def _unexpected(_request: Request, error: Exception) -> JSONResponse:
        logger.error("erro_inesperado tipo=%s", type(error).__name__)
        return JSONResponse(
            status_code=500,
            content=_body("internal_error", "Erro interno. Tente novamente mais tarde."),
        )
