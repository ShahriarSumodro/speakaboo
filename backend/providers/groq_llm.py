"""
Groq LLM Provider

Uses the Groq API for chat completions (OpenAI-compatible endpoint).
Supports automatic fallback models if the primary model is decommissioned or throttled.
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
    """Groq LLM provider with retry, backoff, and model fallback."""

    def __init__(
        self,
        api_key: str,
        model: str = "qwen/qwen3.8-27b",
        fallback_models: Optional[list[str]] = None,
    ):
        if not api_key:
            raise ValueError("Groq API key is required for GroqLlmProvider")
        self._api_key = api_key
        self._model = model
        self._fallback_models = fallback_models or [
            model,
            "qwen/qwen3.8-27b",
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b",
        ]
        # Ensure unique order
        seen = set()
        self._models_to_try = [m for m in [model] + list(self._fallback_models) if not (m in seen or seen.add(m))]

    async def chat(
        self,
        messages: list[Message],
        max_tokens: int = 256,
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> LlmResult:
        if not messages:
            raise ProviderError("No messages provided", provider=self.name)

        last_error: Optional[Exception] = None

        for model_candidate in self._models_to_try:
            payload: dict = {
                "model": model_candidate,
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "max_tokens": max_tokens,
                "temperature": temperature,
            }

            if json_mode:
                payload["response_format"] = {"type": "json_object"}

            backoff = INITIAL_BACKOFF

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
                            f"Groq LLM ({model_candidate}) rate limited (attempt {attempt + 1}/{MAX_RETRIES}), "
                            f"retrying in {retry_after:.1f}s"
                        )
                        if attempt < MAX_RETRIES - 1:
                            await asyncio.sleep(retry_after)
                            backoff *= 2
                            continue
                        # If retries exhausted on this model, try next model in fallback list
                        break

                    if response.status_code in (400, 404):
                        # Often indicates model decommissioned or invalid model name
                        logger.warning(
                            f"Groq model '{model_candidate}' returned HTTP {response.status_code}: "
                            f"{response.text[:200]}. Attempting fallback model."
                        )
                        last_error = ProviderError(
                            f"Model error {response.status_code}: {response.text[:200]}",
                            provider=self.name,
                            status_code=response.status_code,
                        )
                        break

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
                        model=data.get("model", model_candidate),
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
            f"Groq LLM failed across candidates {self._models_to_try}: {last_error}",
            provider=self.name,
        )

    @property
    def name(self) -> str:
        return "groq_llm"
