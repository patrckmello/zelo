"""Registro e histórico de descartes (RF11 e RF12).

Ao registrar, os medicamentos escolhidos saem da farmácia ativa e o histórico
guarda uma cópia do nome, da quantidade e da validade de cada item.
"""

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ..dependencies import CurrentUser, DbDep
from ..errors import ApiError
from ..models import Disposal, DisposalItem, Medication, utc_now
from ..schemas import DisposalIn, DisposalOut

router = APIRouter(prefix="/disposals", tags=["descartes"])


@router.get("", response_model=list[DisposalOut])
def list_disposals(user: CurrentUser, db: DbDep) -> list[Disposal]:
    return list(
        db.scalars(
            select(Disposal)
            .where(Disposal.user_id == user.id)
            .options(selectinload(Disposal.items))
            .order_by(Disposal.disposed_on.desc(), Disposal.created_at.desc())
        )
    )


@router.post("", status_code=201, response_model=DisposalOut)
def create_disposal(body: DisposalIn, user: CurrentUser, db: DbDep) -> Disposal:
    # Tolerância de um dia para diferenças de fuso entre aparelho e servidor.
    if body.disposed_on > (datetime.now(UTC) + timedelta(days=1)).date():
        raise ApiError(422, "invalid_disposal_date", "A data do descarte não pode estar no futuro.")

    requested = list(dict.fromkeys(body.medication_ids))
    found = {
        medication.id: medication
        for medication in db.scalars(
            select(Medication).where(
                Medication.id.in_(requested),
                Medication.user_id == user.id,
                Medication.disposed_at.is_(None),
            )
        )
    }
    if len(found) != len(requested):
        raise ApiError(
            404, "medication_not_found", "Um ou mais medicamentos não foram encontrados."
        )

    point = body.point
    disposal = Disposal(
        user_id=user.id,
        disposed_on=body.disposed_on,
        point_external_id=point.external_id if point else None,
        point_name=point.name.strip() if point else None,
        point_address=point.address.strip() if point and point.address else None,
        notes=body.notes.strip(),
    )
    now = utc_now()
    for position, medication_id in enumerate(requested):
        medication = found[medication_id]
        disposal.items.append(
            DisposalItem(
                position=position,
                medication_name=medication.name,
                quantity=medication.quantity,
                expiration_date=medication.expiration_date,
            )
        )
        medication.disposed_at = now
    db.add(disposal)
    db.flush()
    for medication in found.values():
        medication.disposal_id = disposal.id
    db.commit()
    return disposal
