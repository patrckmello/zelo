"""Medicamentos ativos do usuário autenticado (CRUD isolado por dono)."""

import uuid

from fastapi import APIRouter, Response
from sqlalchemy import select

from ..dependencies import CurrentUser, DbDep
from ..errors import ApiError
from ..models import Medication, User
from ..schemas import MedicationIn, MedicationOut

router = APIRouter(prefix="/medications", tags=["medicamentos"])


def _owned(db: DbDep, user: User, medication_id: uuid.UUID) -> Medication:
    medication = db.scalar(
        select(Medication).where(
            Medication.id == medication_id,
            Medication.user_id == user.id,
            Medication.disposed_at.is_(None),
        )
    )
    if medication is None:
        # 404 também para itens de outra conta: não revela a existência.
        raise ApiError(404, "medication_not_found", "Medicamento não encontrado.")
    return medication


@router.get("", response_model=list[MedicationOut])
def list_medications(user: CurrentUser, db: DbDep) -> list[Medication]:
    return list(
        db.scalars(
            select(Medication)
            .where(Medication.user_id == user.id, Medication.disposed_at.is_(None))
            .order_by(Medication.expiration_date, Medication.name)
        )
    )


@router.post("", status_code=201, response_model=MedicationOut)
def create_medication(body: MedicationIn, user: CurrentUser, db: DbDep) -> Medication:
    medication = Medication(user_id=user.id, **body.model_dump())
    db.add(medication)
    db.commit()
    return medication


@router.put("/{medication_id}", response_model=MedicationOut)
def update_medication(
    medication_id: uuid.UUID, body: MedicationIn, user: CurrentUser, db: DbDep
) -> Medication:
    medication = _owned(db, user, medication_id)
    for field, value in body.model_dump().items():
        setattr(medication, field, value)
    db.commit()
    return medication


@router.delete("/{medication_id}", status_code=204)
def delete_medication(medication_id: uuid.UUID, user: CurrentUser, db: DbDep) -> Response:
    db.delete(_owned(db, user, medication_id))
    db.commit()
    return Response(status_code=204)
