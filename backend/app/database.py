"""Conexão com o banco e sessão por requisição."""

from collections.abc import Iterator

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


def build_engine(database_url: str) -> Engine:
    connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
    engine = create_engine(database_url, pool_pre_ping=True, connect_args=connect_args)
    if database_url.startswith("sqlite"):
        # O SQLite só respeita chaves estrangeiras quando solicitado.
        @event.listens_for(engine, "connect")
        def _enable_foreign_keys(connection, _record) -> None:  # pragma: no cover
            cursor = connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    return engine


class Database:
    def __init__(self, database_url: str) -> None:
        self.engine = build_engine(database_url)
        self.session_factory = sessionmaker(
            bind=self.engine, autoflush=False, expire_on_commit=False
        )

    def session(self) -> Iterator[Session]:
        session = self.session_factory()
        try:
            yield session
        finally:
            session.close()
