"""Configuração lida de variáveis de ambiente e do arquivo `.env` local.

Segredos (chave EcoMed, segredo JWT e senha do banco) nunca têm valor padrão
versionado; consulte `.env.example`.
"""

from functools import lru_cache
from pathlib import Path
from typing import Annotated, Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent

ECOMED_ATTRIBUTION = (
    "Dados: EcoMed — fontes CNES/DATASUS (Ministério da Saúde) e LogMed/Sindusfarma."
)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: Literal["development", "test", "production"] = Field(
        default="development", alias="ZELO_ENV"
    )
    database_url: str = Field(alias="ZELO_DATABASE_URL")
    jwt_secret: SecretStr = Field(alias="ZELO_JWT_SECRET")
    access_token_minutes: int = Field(default=15, alias="ZELO_ACCESS_TOKEN_MINUTES", ge=1)
    refresh_token_days: int = Field(default=30, alias="ZELO_REFRESH_TOKEN_DAYS", ge=1)
    password_reset_minutes: int = Field(default=30, alias="ZELO_PASSWORD_RESET_MINUTES", ge=5)
    password_reset_outbox_dir: Path | None = Field(
        default=None, alias="ZELO_PASSWORD_RESET_OUTBOX_DIR"
    )
    cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=list, alias="ZELO_CORS_ORIGINS"
    )
    cors_origin_regex: str | None = Field(default=None, alias="ZELO_CORS_ORIGIN_REGEX")
    login_attempts_per_window: int = Field(default=10, alias="ZELO_LOGIN_ATTEMPTS", ge=1)
    login_window_seconds: int = Field(default=300, alias="ZELO_LOGIN_WINDOW_SECONDS", ge=1)

    demo_email: str = Field(default="demo@zelo.app", alias="ZELO_DEMO_EMAIL")
    demo_password: SecretStr | None = Field(default=None, alias="ZELO_DEMO_PASSWORD")

    ocr_engine: Literal["rapidocr", "tesseract"] = Field(
        default="rapidocr", alias="ZELO_OCR_ENGINE"
    )
    ecomed_api_key: SecretStr | None = Field(default=None, alias="ECOMED_API_KEY")
    ecomed_base_url: str = Field(
        default="https://ecomed.eco.br/api/public/v1", alias="ECOMED_BASE_URL"
    )
    ecomed_timeout_seconds: float = Field(default=8.0, alias="ECOMED_TIMEOUT_SECONDS", gt=0)
    ecomed_cache_ttl_seconds: int = Field(default=300, alias="ECOMED_CACHE_TTL_SECONDS", ge=0)
    ecomed_rate_limit_per_minute: int = Field(
        default=60, alias="ECOMED_RATE_LIMIT_PER_MINUTE", ge=1
    )

    @field_validator("jwt_secret")
    @classmethod
    def _strong_secret(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < 32:
            raise ValueError("ZELO_JWT_SECRET deve ter pelo menos 32 caracteres.")
        return value

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @field_validator("ecomed_api_key", mode="before")
    @classmethod
    def _blank_key_is_missing(cls, value: object) -> object:
        if isinstance(value, str) and not value.strip():
            return None
        return value

    @property
    def ecomed_configured(self) -> bool:
        return self.ecomed_api_key is not None


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
