"""Pontos de coleta próximos, sempre via EcoMed no servidor (D003)."""

import logging
from typing import Annotated

from fastapi import APIRouter, Query
from starlette.concurrency import run_in_threadpool

from ..config import ECOMED_ATTRIBUTION
from ..dependencies import ContainerDep, CurrentUser
from ..errors import ApiError
from ..schemas import CollectionPointOut, NearbyCollectionPointsOut
from ..services.ecomed import DEFAULT_RADIUS_M, MAX_RADIUS_M, MIN_RADIUS_M, EcoMedError

router = APIRouter(prefix="/collection-points", tags=["pontos de coleta"])
logger = logging.getLogger("zelo.collection_points")

_UNAVAILABLE = "Não foi possível consultar os pontos agora. Tente novamente."


def _to_api_error(error: EcoMedError) -> ApiError:
    match error.failure:
        case "not_configured":
            return ApiError(
                503,
                "collection_points_not_configured",
                "A consulta de pontos ainda não foi configurada no servidor.",
            )
        case "rate_limited":
            retry = max(int(error.retry_after or 30), 1)
            return ApiError(
                503,
                "collection_points_rate_limited",
                "Muitas consultas de pontos agora. Tente novamente em instantes.",
                headers={"Retry-After": str(retry)},
            )
        case "timeout":
            return ApiError(
                504,
                "collection_points_timeout",
                "A fonte de pontos demorou a responder. Tente novamente.",
            )
        case "not_found":
            return ApiError(404, "collection_point_not_found", "Ponto não encontrado.")
        case "unauthorized":
            logger.error("ecomed_chave_recusada")
            return ApiError(502, "collection_points_unavailable", _UNAVAILABLE)
        case _:
            return ApiError(502, "collection_points_unavailable", _UNAVAILABLE)


@router.get("/nearby", response_model=NearbyCollectionPointsOut)
async def nearby(
    _user: CurrentUser,
    container: ContainerDep,
    latitude: Annotated[float, Query(ge=-90, le=90)],
    longitude: Annotated[float, Query(ge=-180, le=180)],
    radius_m: Annotated[int, Query(ge=MIN_RADIUS_M, le=MAX_RADIUS_M)] = DEFAULT_RADIUS_M,
) -> NearbyCollectionPointsOut:
    try:
        points, cache = await run_in_threadpool(
            container.collection_points.nearby, latitude, longitude, radius_m
        )
    except EcoMedError as error:
        raise _to_api_error(error) from None
    return NearbyCollectionPointsOut(
        points=[CollectionPointOut(**point.as_dict()) for point in points],
        count=len(points),
        radius_m=radius_m,
        attribution=ECOMED_ATTRIBUTION,
        cache=cache,
    )


@router.get("/{point_id}", response_model=CollectionPointOut)
async def detail(point_id: str, _user: CurrentUser, container: ContainerDep) -> CollectionPointOut:
    try:
        point = await run_in_threadpool(container.collection_points.detail, point_id)
    except EcoMedError as error:
        raise _to_api_error(error) from None
    return CollectionPointOut(**point.as_dict())
