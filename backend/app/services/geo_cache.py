"""Cache com expiração para respostas da EcoMed.

A chave usa latitude e longitude arredondadas a três casas (~110 m), de modo
que buscas próximas reutilizam a mesma resposta e o limite externo é poupado.
"""

import threading
import time
from collections.abc import Callable, Hashable


def round_coordinate(value: float) -> float:
    return round(value, 3)


def nearby_cache_key(latitude: float, longitude: float, radius_m: int) -> tuple:
    return ("nearby", round_coordinate(latitude), round_coordinate(longitude), radius_m)


class TtlCache[T]:
    def __init__(
        self,
        ttl_seconds: float,
        max_entries: int = 512,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.ttl_seconds = ttl_seconds
        self.max_entries = max_entries
        self._clock = clock
        self._entries: dict[Hashable, tuple[float, T]] = {}
        self._lock = threading.Lock()
        self.hits = 0
        self.misses = 0

    def get(self, key: Hashable) -> T | None:
        now = self._clock()
        with self._lock:
            entry = self._entries.get(key)
            if entry is None or entry[0] <= now:
                if entry is not None:
                    del self._entries[key]
                self.misses += 1
                return None
            self.hits += 1
            return entry[1]

    def set(self, key: Hashable, value: T) -> None:
        if self.ttl_seconds <= 0:
            return
        now = self._clock()
        with self._lock:
            if len(self._entries) >= self.max_entries:
                expired = [k for k, (expiry, _) in self._entries.items() if expiry <= now]
                for k in expired:
                    del self._entries[k]
                if len(self._entries) >= self.max_entries:
                    oldest = min(self._entries, key=lambda k: self._entries[k][0])
                    del self._entries[oldest]
            self._entries[key] = (now + self.ttl_seconds, value)

    def clear(self) -> None:
        with self._lock:
            self._entries.clear()
