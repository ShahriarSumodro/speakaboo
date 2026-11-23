"""
CLI Chat - Test conversation with a Speakaboo character.

Usage:
  python -m backend.cli_chat                  # Text-only chat with mock providers
  python -m backend.cli_chat --audio FILE     # Process a single audio file
  python -m backend.cli_chat --provider groq  # Use real Groq providers (needs API key)

This is the GATE 1 verification tool.
"""

import asyncio
import json
import sys
import os
import argparse
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.config import load_settings
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider
from backend.engine.conversation import ConversationEngine
from backend.engine.characters import load_character, list_characters


def create_engine(provider_type: str = "mock"):
    """Create a conversation engine with the specified provider type."""
    settings = load_settings()

    if provider_type == "groq":
        from backend.providers.groq_stt import GroqSttProvider
        from backend.providers.groq_llm import GroqLlmProvider
        from backend.providers.groq_tts import GroqTtsProvider

        stt = GroqSttProvider(api_key=settings.stt.api_key, model=settings.stt.model)
        llm = GroqLlmProvider(api_key=settings.llm.api_key, model=settings.llm.model)
        tts = GroqTtsProvider(api_key=settings.tts.api_key, model=settings.tts.model)
    else:
        stt = MockSttProvider()
        llm = MockLlmProvider()
        tts = MockTtsProvider()

    return ConversationEngine(stt=stt, llm=llm, tts=tts)


async def text_chat(engine: ConversationEngine, character_id: str):
    """Interactive text chat mode (uses mock STT — just types text)."""
    character = load_character(character_id)
    state = engine.start_conversation(character_id, "cli-user")

    print(f"\n{'='*60}")
    print(f"  Speakaboo CLI Chat")
    print(f"  Character: {character.name}")
    print(f"  {character.description}")
    print(f"{'='*60}")
    print(f"\n{character.name}: {character.greeting}\n")
    print("Type your message (or 'quit' to exit):\n")

    mock_stt = engine._stt
    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if user_input.lower() in ("quit", "exit", "q"):
            print(f"\n{character.name}: Goodbye! Keep practicing every day!")
            break

        if not user_input:
            continue

        # Set the mock STT to return the typed text
        if hasattr(mock_stt, 'set_next_response'):
            mock_stt.set_next_response(user_input)

        result = await engine.process_turn(
            conversation_id=state.id,
            audio=b"\x00" * 1000,  # dummy audio
            character=character,
        )

        # Display response
        print(f"\n{character.name}: {result.response.reply}")

        if result.response.correction:
            c = result.response.correction
            print(f"  💡 Correction: '{c.original}' → '{c.better}'")
            print(f"     ({c.reason_short})")

        if result.response.new_words:
            print(f"  📚 New words: {', '.join(result.response.new_words)}")

        if result.safety_blocked:
            print(f"  ⚠️  (Content was redirected for safety)")

        print(f"  [Level: {result.level} | Latency: {result.latency_ms:.0f}ms]")
        print()


async def audio_chat(engine: ConversationEngine, character_id: str, audio_path: str):
    """Process a single audio file."""
    character = load_character(character_id)
    state = engine.start_conversation(character_id, "cli-user")

    print(f"\nProcessing audio: {audio_path}")
    print(f"Character: {character.name}\n")

    with open(audio_path, "rb") as f:
        audio_bytes = f.read()

    # Detect format from extension
    ext = Path(audio_path).suffix.lstrip(".")
    fmt = ext if ext in ("wav", "mp3", "ogg", "webm", "m4a") else "wav"

    result = await engine.process_turn(
        conversation_id=state.id,
        audio=audio_bytes,
        character=character,
        audio_format=fmt,
    )

    print(f"You said: {result.user_transcript}")
    print(f"{character.name}: {result.response.reply}")

    if result.response.correction:
        c = result.response.correction
        print(f"  💡 Correction: '{c.original}' → '{c.better}' ({c.reason_short})")

    if result.response.new_words:
        print(f"  📚 New words: {', '.join(result.response.new_words)}")

    print(f"\n--- Stats ---")
    print(f"STT: {result.stt_seconds:.1f}s audio")
    print(f"LLM: {result.llm_tokens_in} in / {result.llm_tokens_out} out tokens")
    print(f"TTS: {result.tts_chars} chars → {len(result.audio_chunks)} chunk(s)")
    print(f"Latency: {result.latency_ms:.0f}ms")
    print(f"Level: {result.level}")

    # Save output audio if any
    if result.audio_chunks:
        out_path = Path(audio_path).stem + "_reply.wav"
        with open(out_path, "wb") as f:
            for chunk in result.audio_chunks:
                f.write(chunk)
        print(f"Reply audio saved to: {out_path}")


def main():
    parser = argparse.ArgumentParser(description="Speakaboo CLI Chat")
    parser.add_argument("--character", "-c", default="rule_farmer", help="Character ID")
    parser.add_argument("--provider", "-p", default="mock", choices=["mock", "groq"], help="Provider type")
    parser.add_argument("--audio", "-a", help="Path to audio file for single-turn mode")
    parser.add_argument("--list-characters", action="store_true", help="List available characters")
    args = parser.parse_args()

    if args.list_characters:
        chars = list_characters()
        print("\nAvailable characters:")
        for c in chars:
            lock = "🔒" if c.locked else "🔓"
            print(f"  {lock} {c.id}: {c.name} - {c.description}")
        return

    engine = create_engine(args.provider)

    if args.audio:
        asyncio.run(audio_chat(engine, args.character, args.audio))
    else:
        asyncio.run(text_chat(engine, args.character))


if __name__ == "__main__":
    main()
