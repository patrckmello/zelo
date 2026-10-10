from pathlib import Path

from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.migration import MigrationContext
from sqlalchemy import create_engine, inspect

from app.database import Base

BACKEND_DIR = Path(__file__).resolve().parent.parent


def _alembic_config(url: str) -> Config:
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    config.set_main_option("sqlalchemy.url", url)
    return config


def test_migracoes_criam_o_esquema_dos_modelos_em_banco_limpo(tmp_path):
    url = f"sqlite:///{(tmp_path / 'migracao.db').as_posix()}"
    config = _alembic_config(url)

    command.upgrade(config, "head")
    engine = create_engine(url)
    with engine.connect() as connection:
        tables = set(inspect(connection).get_table_names())
        differences = compare_metadata(MigrationContext.configure(connection), Base.metadata)
    assert {"users", "medications", "disposals", "disposal_items"} <= tables
    assert differences == []

    command.downgrade(config, "base")
    with engine.connect() as connection:
        assert set(inspect(connection).get_table_names()) == {"alembic_version"}
    engine.dispose()


def test_health_informa_banco_e_configuracao(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "database": "ok",
        "ecomed_configured": True,
        "ocr_available": True,
    }


def test_erros_seguem_formato_estavel(client):
    response = client.get("/v1/rota-inexistente")
    assert response.status_code == 404
    assert response.json() == {"error": {"code": "not_found", "message": "Recurso não encontrado."}}
