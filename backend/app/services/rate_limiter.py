"""Limitador por janela deslizante, em memória e seguro entre threads.

Usado para respeitar o limite compartilhado da EcoMed (60 requisições por
minuto por chave) e para conter tentativas repetidas de login.
"""

import threading
import time
from collections import deque
from collections.abc import Callable


class SlidingWindowLimiter:
    def __init__(
        self,
        limit: int,
        window_seconds: float,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self._clock = clock
        self._events: dict[str, deque[float]] = {}
        self._lock = threading.Lock()

    def try_acquire(self, key: str = "global") -> float | None:
        """Registra uma ocorrência e devolve `None`, ou os segundos de espera."""
        now = self._clock()
        with self._lock:
            events = self._events.setdefault(key, deque())
            while events and now - events[0] >= self.window_seconds:
                events.popleft()
            if len(events) >= self.limit:
                return max(self.window_seconds - (now - events[0]), 0.0)
            events.append(now)
            return None

    def reset(self, key: str = "global") -> None:
        with self._lock:
            self._events.pop(key, None)
