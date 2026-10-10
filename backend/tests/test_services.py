import pytest

from app.services.ecomed import (
    EcoMedError,
    normalize_nearby_payload,
    normalize_point,
    normalize_residue_types,
)
from app.services.geo_cache import TtlCache, nearby_cache_key
from app.services.rate_limiter import SlidingWindowLimiter


class FakeClock:
    def __init__(self) -> None:
        self.now = 1000.0

    def __call__(self) -> float:
        return self.now


def test_normaliza_variantes_de_residuos():
    assert normalize_residue_types(
        [" Medicamentos", "medicamento", "SERINGAS", "Lâmpadas", 3, ""]
    ) == ("medicamento", "seringa", "lâmpadas")
    assert normalize_residue_types(None) == ()


def test_ponto_sem_dados_essenciais_e_ignorado():
    assert normalize_point({"id": "x", "name": "Sem coordenadas"}) is None
    assert normalize_point({"id": "", "name": "A", "latitude": 1, "longitude": 1}) is None
    assert normalize_point({"id": "a", "name": "A", "latitude": 95, "longitude": 1}) is None
    assert normalize_point("texto") is None


def test_ponto_normalizado_identifica_origem():
    point = normalize_point(
        {
            "id": "LOGMED-000001",
            "name": "Farmácia",
            "latitude": "-30.0",
            "longitude": -51,
            "distancia_metros": -3,
        }
    )
    assert point is not None
    assert point.origin == "logmed"
    assert point.distance_m is None
    assert point.phone is None


def test_payload_sem_lista_de_pontos_e_invalido():
    with pytest.raises(EcoMedError) as error:
        normalize_nearby_payload({"count": 0})
    assert error.value.failure == "invalid_response"


def test_cache_usa_coordenadas_arredondadas_e_expira():
    clock = FakeClock()
    cache: TtlCache[str] = TtlCache(ttl_seconds=60, clock=clock)
    cache.set(nearby_cache_key(-30.03461, -51.21771, 5000), "valor")

    assert cache.get(nearby_cache_key(-30.0349, -51.2175, 5000)) == "valor"
    clock.now += 61
    assert cache.get(nearby_cache_key(-30.0349, -51.2175, 5000)) is None
    assert (cache.hits, cache.misses) == (1, 1)


def test_cache_desativado_com_ttl_zero():
    cache: TtlCache[str] = TtlCache(ttl_seconds=0)
    cache.set("chave", "valor")
    assert cache.get("chave") is None


def test_janela_deslizante_libera_apos_o_intervalo():
    clock = FakeClock()
    limiter = SlidingWindowLimiter(limit=2, window_seconds=60, clock=clock)

    assert limiter.try_acquire() is None
    clock.now += 10
    assert limiter.try_acquire() is None
    assert limiter.try_acquire() == pytest.approx(50)
    clock.now += 51
    assert limiter.try_acquire() is None
