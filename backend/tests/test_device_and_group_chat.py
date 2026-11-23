"""
Tests for Phase 6 Device Readiness:
DeviceTransport BLE stub and Multi-character Group Chat engine.
"""

import pytest
import os
from unittest.mock import patch

from backend.engine.device_transport import (
    BleDeviceStub,
    ConnectionState,
    DeviceEventType,
    DeviceInfo,
)
from backend.engine.group_chat import (
    GroupChatEngine,
    FeatureDisabledError,
)
from backend.providers.mock import MockLlmProvider, MockTtsProvider
from backend.config import load_settings, Settings, FeatureFlags


@pytest.mark.asyncio
async def test_ble_device_stub_scan():
    stub = BleDeviceStub()
    devices = await stub.scan()
    assert len(devices) >= 2
    assert any("Speakaboo Toy" in d.name for d in devices)


@pytest.mark.asyncio
async def test_ble_device_stub_connect_and_disconnect():
    stub = BleDeviceStub()
    assert stub.state == ConnectionState.DISCONNECTED

    # Connect to valid device
    success = await stub.connect("ble:spk-toy-001")
    assert success is True
    assert stub.state == ConnectionState.CONNECTED
    assert stub.connected_device is not None
    assert stub.connected_device.device_id == "ble:spk-toy-001"

    # Events drained
    events = await stub.get_events()
    assert len(events) >= 1
    assert events[0].event_type == DeviceEventType.STATE_CHANGED

    # Disconnect
    await stub.disconnect()
    assert stub.state == ConnectionState.DISCONNECTED
    assert stub.connected_device is None


@pytest.mark.asyncio
async def test_ble_device_stub_audio_relay_and_events():
    stub = BleDeviceStub()
    await stub.connect("ble:spk-toy-001")

    # Send audio to toy speaker
    sent = await stub.send_audio_chunk(b"RIFF_FAKE_AUDIO_OUT")
    assert sent is True
    assert len(stub._outgoing_audio_log) == 1

    # Simulate mic audio from toy
    await stub.simulate_microphone_audio(b"RIFF_FAKE_AUDIO_IN")
    received = await stub.receive_audio_chunk()
    assert received == b"RIFF_FAKE_AUDIO_IN"

    # Push-to-talk button simulation
    await stub.simulate_button_press()
    await stub.simulate_button_release()
    events = await stub.get_events()
    event_types = [e.event_type for e in events]
    assert DeviceEventType.BUTTON_PRESSED in event_types
    assert DeviceEventType.BUTTON_RELEASED in event_types

    # Hardware control commands
    cmd_ok = await stub.send_command("set_led", {"color": "#F26B21"})
    assert cmd_ok is True
    assert stub._led_color == "#F26B21"


@pytest.mark.asyncio
async def test_group_chat_disabled_by_default():
    llm = MockLlmProvider()
    tts = MockTtsProvider()
    engine = GroupChatEngine(llm=llm, tts=tts)

    with pytest.raises(FeatureDisabledError):
        await engine.create_session(
            session_id="gsess-1",
            user_id="user-1",
            character_ids=["rule_farmer", "dhaka_detective"],
        )


@pytest.mark.asyncio
async def test_group_chat_multi_character_turn():
    # Enable feature flag via monkeypatch of load_settings
    current_settings = load_settings()
    custom_flags = FeatureFlags(
        constructive_criticism_mode=False,
        multi_character_group_chat=True,
    )
    patched_settings = Settings(
        server=current_settings.server,
        stt=current_settings.stt,
        llm=current_settings.llm,
        tts=current_settings.tts,
        safety=current_settings.safety,
        usage=current_settings.usage,
        database=current_settings.database,
        payment=current_settings.payment,
        features=custom_flags,
    )

    with patch("backend.engine.group_chat.load_settings", return_value=patched_settings):
        llm = MockLlmProvider()
        tts = MockTtsProvider()
        engine = GroupChatEngine(llm=llm, tts=tts)

        session = await engine.create_session(
            session_id="gsess-100",
            user_id="user-100",
            character_ids=["rule_farmer", "dhaka_detective"],
        )
        assert len(session.characters) == 2
        assert session.characters[0].id == "rule_farmer"
        assert session.characters[1].id == "dhaka_detective"

        # Safe turn execution
        turn_res = await engine.process_turn(
            session=session,
            user_text="Good morning everyone! How is the harvest today?",
            learner_level="beginner",
        )

        assert len(turn_res.speakers_output) == 2
        assert turn_res.speakers_output[0].character_id == "rule_farmer"
        assert turn_res.speakers_output[1].character_id == "dhaka_detective"
        assert len(turn_res.speakers_output[0].audio_chunks) > 0

        # Safety blocked turn redirection
        unsafe_turn = await engine.process_turn(
            session=session,
            user_text="Let's make dangerous weapons and fight",
            learner_level="beginner",
        )
        assert len(unsafe_turn.speakers_output) == 1
        assert "friendly" in unsafe_turn.speakers_output[0].reply
