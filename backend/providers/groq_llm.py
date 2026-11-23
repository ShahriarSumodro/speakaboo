"""
Groq LLM Provider

Uses the Groq API for chat completions (OpenAI-compatible endpoint).
"""

import logging
import asyncio
import json
from typing import Optional

import httpx

from backend.providers.base import (
    LlmProvider, Message, LlmResult, ProviderError, RateLimitError,
)

logger = logging.getLogger("speakaboo.providers.groq_llm")

GROQ_CHAT_URL = "https://api.groq.com/openai/v1/chat/completions"
MAX_RETRIES = 3
INITIAL_BACKOFF = 1.0


class GroqLlmProvider(LlmProvider):
    """Groq LLM provider with retry and backoff."""

    def __init__(self, api_key: str, model: str = "meta-llama/llama-4-scout-17b-16e-instruct"):
        if not api_key:
            raise ValueError("Groq API key is required for GroqLlmProvider")
        self._api_key = api_key
        self._model = model

    async def chat(
        self,
        messages: list[Message],
        max_tokens: int = 256,
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> LlmResult:
        if not messages:
            raise ProviderError("No messages provided", provider=self.name)

        payload: dict = {
            "model": self._model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        if json_mode:
            payload["response_format"] = {"type": "json_object"}

        backoff = INITIAL_BACKOFF
        last_error: Optional[Exception] = None

        for attempt in range(MAX_RETRIES):
            try:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.post(
                        GROQ_CHAT_URL,
                        headers={
                            "Authorization": f"Bearer {self._api_key}",
                            "Content-Type": "application/json",
                        },
                        json=payload,
                    )

                if response.status_code == 429:
                    retry_after = float(response.headers.get("retry-after", backoff))
                    logger.warning(
                        f"Groq LLM rate limited (attempt {attempt + 1}/{MAX_RETRIES}), "
                        f"retrying in {retry_after:.1f}s"
                    )
                    if attempt < MAX_RETRIES - 1:
                        await asyncio.sleep(retry_after)
                        backoff *= 2
                        continue
                    raise RateLimitError(
                        "Groq LLM rate limit exceeded after retries",
                        provider=self.name,
                        retry_after=retry_after,
                    )

                if response.status_code != 200:
                    raise ProviderError(
                        f"Groq LLM error: {response.status_code} {response.text[:200]}",
                        provider=self.name,
                        status_code=response.status_code,
                    )

                data = response.json()
                choice = data["choices"][0]
                usage = data.get("usage", {})

                return LlmResult(
                    content=choice["message"]["content"],
                    tokens_in=usage.get("prompt_tokens", 0),
                    tokens_out=usage.get("completion_tokens", 0),
                    model=data.get("model", self._model),
                )

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                last_error = e
                logger.warning(
                    f"Groq LLM connection error (attempt {attempt + 1}/{MAX_RETRIES}): {e}"
                )
                if attempt < MAX_RETRIES - 1:
                    await asyncio.sleep(backoff)
                    backoff *= 2

        raise ProviderError(
            f"Groq LLM failed after {MAX_RETRIES} retries: {last_error}",
            provider=self.name,
        )

    @property
    def name(self) -> str:
        return "groq_llm"
