"""Contratos de entrada e saída da API Zelo (prefixo /v1)."""

import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


def _strip(value: str) -> str:
    return value.strip()


# ---------------------------------------------------------------- autenticação


class RegisterRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

    _strip_name = field_validator("name")(_strip)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=16, max_length=256)


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    token: str = Field(min_length=16, max_length=256)
    new_password: str = Field(min_length=8, max_length=128)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    email: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"] = "bearer"  # noqa: S105 - tipo, não segredo
    expires_in: int
    user: UserOut


# ---------------------------------------------------------------- conta


class AccountOut(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    created_at: datetime
    medications_count: int
    disposals_count: int


class AccountUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=120)

    @field_validator("name")
    @classmethod
    def _name_not_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("O nome não pode ficar em branco.")
        return value


class EmailChange(BaseModel):
    new_email: EmailStr
    current_password: str = Field(min_length=1, max_length=128)


class PasswordChange(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class AccountDeletion(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)


# ---------------------------------------------------------------- medicamentos


class MedicationIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    expiration_date: date
    quantity: int = Field(ge=1, le=100_000)
    notes: str = Field(default="", max_length=500)

    @field_validator("name", "notes")
    @classmethod
    def _trimmed(cls, value: str) -> str:
        return value.strip()

    @field_validator("name")
    @classmethod
    def _name_not_blank(cls, value: str) -> str:
        if not value:
            raise ValueError("O nome não pode ficar em branco.")
        return value


class MedicationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    expiration_date: date
    quantity: int
    notes: str


# ---------------------------------------------------------------- descartes


class DisposalPointIn(BaseModel):
    external_id: str | None = Field(default=None, max_length=64)
    name: str = Field(min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=300)


class DisposalIn(BaseModel):
    medication_ids: list[uuid.UUID] = Field(min_length=1, max_length=100)
    disposed_on: date
    point: DisposalPointIn | None = None
    notes: str = Field(default="", max_length=500)


class DisposalItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    medication_name: str
    quantity: int
    expiration_date: date


class DisposalOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    disposed_on: date
    point_external_id: str | None
    point_name: str | None
    point_address: str | None
    notes: str
    items: list[DisposalItemOut]


# ---------------------------------------------------------------- pontos de coleta


class CollectionPointOut(BaseModel):
    id: str
    name: str
    address: str
    city: str
    state: str
    latitude: float
    longitude: float
    phone: str | None
    residue_types: list[str]
    distance_m: int | None
    origin: Literal["logmed", "other"]
    requires_confirmation: bool


class NearbyCollectionPointsOut(BaseModel):
    points: list[CollectionPointOut]
    count: int
    radius_m: int
    attribution: str
    cache: Literal["hit", "miss"]


# ---------------------------------------------------------------- leitura de embalagem


class MedicationScanOut(BaseModel):
    name_candidates: list[str]
    expiration_date: date | None
    expiration_text: str | None
    expiration_has_day: bool
    quantity: int | None
    text: str
