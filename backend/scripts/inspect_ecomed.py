"""Inspeciona a estrutura real da API EcoMed sem expor segredos.

Uso (na pasta backend/, com ECOMED_API_KEY no arquivo .env):

    python -m scripts.inspect_ecomed
    python -m scripts.inspect_ecomed --lat -29.920 --lng -51.180 --raio 5000 --detalhe

Mostra o status HTTP, os cabeçalhos de limite, os campos e tipos devolvidos,
as variantes de `residueTypes`, os prefixos de ID e a estrutura de `schedules`.
Não imprime a chave, endereços, telefones ou coordenadas dos pontos. Faz no
máximo duas requisições (proximos e, opcionalmente, um detalhe).
"""

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import httpx
from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent

# Centro de Porto Alegre (Wikidata), recorte inicial do projeto.
DEFAULT_LAT = -30.033
DEFAULT_LNG = -51.230


class EcoMedSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env", env_file_encoding="utf-8", extra="ignore"
    )

    api_key: SecretStr | None = Field(default=None, alias="ECOMED_API_KEY")
    base_url: str = Field(default="https://ecomed.eco.br/api/public/v1", alias="ECOMED_BASE_URL")


def describe(value: Any, depth: int = 0) -> Any:
    """Estrutura (tipos e chaves) sem os valores."""
    if isinstance(value, dict):
        if depth >= 3:
            return "objeto"
        return {key: describe(item, depth + 1) for key, item in sorted(value.items())}
    if isinstance(value, list):
        if not value:
            return "lista vazia"
        kinds = sorted(
            {json.dumps(describe(item, depth + 1), ensure_ascii=False) for item in value}
        )
        return [json.loads(kind) for kind in kinds[:3]]
    if value is None:
        return "null"
    return type(value).__name__


def id_prefix(point_id: Any) -> str:
    if not isinstance(point_id, str):
        return f"<{type(point_id).__name__}>"
    match = re.match(r"^([A-Za-z]+)[-_]", point_id)
    return f"{match.group(1).lower()}-*" if match else "sem prefixo"


def summarize(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        return {"formato_raiz": type(payload).__name__}
    points = payload.get("pontos") if isinstance(payload.get("pontos"), list) else []
    residues: Counter[str] = Counter()
    keys: Counter[str] = Counter()
    schedules: list[Any] = []
    for point in points:
        if not isinstance(point, dict):
            continue
        keys.update(point.keys())
        for residue in point.get("residueTypes") or []:
            residues[str(residue)] += 1
        if point.get("schedules"):
            schedules.append(describe(point["schedules"]))
    return {
        "campos_raiz": describe({k: v for k, v in payload.items() if k != "pontos"}),
        "quantidade_de_pontos": len(points),
        "campos_dos_pontos": dict(keys),
        "estrutura_dos_pontos": describe(points[:5]),
        "variantes_residueTypes": dict(residues),
        "prefixos_de_id": dict(
            Counter(id_prefix(p.get("id")) for p in points if isinstance(p, dict))
        ),
        "pontos_com_schedules": len(schedules),
        "estrutura_schedules": schedules[:2],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--lat", type=float, default=DEFAULT_LAT)
    parser.add_argument("--lng", type=float, default=DEFAULT_LNG)
    parser.add_argument("--raio", type=int, default=5000)
    parser.add_argument("--detalhe", action="store_true", help="consulta também um ponto")
    parser.add_argument("--saida", type=Path, help="grava o resumo em JSON")
    args = parser.parse_args()

    settings = EcoMedSettings()
    if settings.api_key is None or not settings.api_key.get_secret_value().strip():
        print("ECOMED_API_KEY não está definida em backend/.env.", file=sys.stderr)
        return 2

    headers = {
        "X-API-Key": settings.api_key.get_secret_value(),
        "Accept": "application/json",
        "User-Agent": "ZeloAPI/1.0 (inspecao de contrato)",
    }
    report: dict[str, Any] = {}
    with httpx.Client(
        base_url=settings.base_url.rstrip("/") + "/", headers=headers, timeout=15
    ) as client:
        response = client.get(
            "pontos/proximos",
            params={"lat": round(args.lat, 3), "lng": round(args.lng, 3), "raio": args.raio},
        )
        report["proximos"] = {
            "status": response.status_code,
            "limite": {
                name: response.headers.get(name)
                for name in ("X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset")
            },
            "content_type": response.headers.get("content-type"),
        }
        try:
            payload = response.json()
        except ValueError:
            payload = None
            report["proximos"]["erro"] = "resposta não é JSON"
        if response.is_success and payload is not None:
            report["proximos"]["resumo"] = summarize(payload)

        first_id = None
        if isinstance(payload, dict) and isinstance(payload.get("pontos"), list):
            first_id = next(
                (p.get("id") for p in payload["pontos"] if isinstance(p, dict) and p.get("id")),
                None,
            )
        if (
            args.detalhe
            and isinstance(first_id, str)
            and re.fullmatch(r"[A-Za-z0-9_-]{1,64}", first_id)
        ):
            detail = client.get(f"pontos/{first_id}")
            report["detalhe"] = {"status": detail.status_code, "prefixo_id": id_prefix(first_id)}
            try:
                report["detalhe"]["estrutura"] = describe(detail.json())
            except ValueError:
                report["detalhe"]["erro"] = "resposta não é JSON"

    text = json.dumps(report, ensure_ascii=False, indent=2)
    print(text)
    if args.saida:
        args.saida.parent.mkdir(parents=True, exist_ok=True)
        args.saida.write_text(text, encoding="utf-8")
    return 0 if report["proximos"]["status"] == 200 else 1


if __name__ == "__main__":
    raise SystemExit(main())
