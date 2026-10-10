"""Cria ou recria a conta de demonstração com medicamentos fictícios.

Uso (na pasta backend/, depois de `alembic upgrade head`):

    python -m scripts.seed_demo            # cria se ainda não existir
    python -m scripts.seed_demo --reset    # recria os medicamentos de exemplo

O e-mail vem de ZELO_DEMO_EMAIL (padrão demo@zelo.app) e a senha de
ZELO_DEMO_PASSWORD, definida somente no .env local. Os medicamentos são
fictícios e relativos à data de hoje: um válido, um próximo do vencimento e
um vencido.
"""

import argparse
import sys
from datetime import date, timedelta

from sqlalchemy import delete, select

from app.config import get_settings
from app.database import Database
from app.models import Medication, User
from app.security import hash_password

EXAMPLES = [
    ("Dipirona", 90, 8, "Comprimidos guardados no armário da cozinha."),
    ("Loratadina", 12, 6, ""),
    ("Soro fisiológico", -5, 1, "Separado para descarte responsável."),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--reset", action="store_true")
    args = parser.parse_args()

    settings = get_settings()
    email = settings.demo_email.strip().lower()
    password = settings.demo_password.get_secret_value() if settings.demo_password else ""
    if len(password) < 8:
        print("Defina ZELO_DEMO_PASSWORD (8+ caracteres) no .env local.", file=sys.stderr)
        return 2

    database = Database(settings.database_url)
    with database.session_factory() as db:
        user = db.scalar(select(User).where(User.email == email))
        if user is None:
            user = User(name="Conta de demonstração", email=email, password_hash="")
            db.add(user)
        user.password_hash = hash_password(password)
        db.flush()

        has_items = db.scalar(select(Medication.id).where(Medication.user_id == user.id))
        if args.reset:
            db.execute(delete(Medication).where(Medication.user_id == user.id))
        if args.reset or has_items is None:
            today = date.today()
            for name, days, quantity, notes in EXAMPLES:
                db.add(
                    Medication(
                        user_id=user.id,
                        name=name,
                        expiration_date=today + timedelta(days=days),
                        quantity=quantity,
                        notes=notes,
                    )
                )
        db.commit()
    database.engine.dispose()
    print(f"Conta de demonstração pronta: {email}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
