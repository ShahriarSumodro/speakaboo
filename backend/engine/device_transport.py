"""
Device Transport interface and Bluetooth Low Energy (BLE) stub for Speakaboo.

Enables communication with a physical companion toy device:
- Audio relay in (microphone from physical toy)
- Audio relay out (speaker on physical toy)
- Hardware status events (push-to-talk button, battery level, LED states)
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
import asyncio
import time
from typing import List, Optional, Dict, Any


class ConnectionState(str, Enum):
    DISCONNECTED = "disconnected"
    SCANNING = "scanning"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    ERROR = "error"


class DeviceEventType(str, Enum):
    BUTTON_PRESSED = "button_pressed"
    BUTTON_RELEASED = "button_released"
    BATTERY_LEVEL = "battery_level"
    STATE_CHANGED = "state_changed"
    AUDIO_OVERFLOW = "audio_overflow"
    ERROR = "error"


@dataclass
class DeviceInfo:
    """Discovered Bluetooth LE toy device."""
    device_id: str
    name: str
    rssi: int = -60
    battery_percentage: int = 100
    firmware_version: str = "1.0.0-stub"
    is_paired: bool = False


@dataclass
class DeviceEvent:
    """Event received from physical toy."""
    event_type: DeviceEventType
    timestamp: float = field(default_factory=time.time)
    payload: Dict[str, Any] = field(default_factory=dict)


class DeviceTransport(ABC):
    """
    Abstract interface for physical companion toy communication.
    Supports Bluetooth LE, USB, or local network transports.
    """

    @abstractmethod
    async def scan(self, timeout_seconds: float = 3.0) -> List[DeviceInfo]:
        """Scan for nearby companion toy devices."""
        pass

    @abstractmethod
    async def connect(self, device_id: str) -> bool:
        """Connect to a specific device."""
        pass

    @abstractmethod
    async def disconnect(self) -> None:
        """Disconnect from the currently connected device."""
        pass

    @abstractmethod
    async def send_audio_chunk(self, chunk: bytes) -> bool:
        """Send an audio chunk to the toy's speaker."""
        pass

    @abstractmethod
    async def receive_audio_chunk(self) -> Optional[bytes]:
        """Receive an audio chunk from the toy's microphone."""
        pass

    @abstractmethod
    async def send_command(self, command: str, params: Optional[Dict[str, Any]] = None) -> bool:
        """Send a control command (e.g. set LED color, set volume)."""
        pass

    @abstractmethod
    async def get_events(self) -> List[DeviceEvent]:
        """Retrieve and drain pending hardware events."""
        pass

    @property
    @abstractmethod
    def state(self) -> ConnectionState:
        """Current connection state."""
        pass

    @property
    @abstractmethod
    def connected_device(self) -> Optional[DeviceInfo]:
        """Currently connected device info or None."""
        pass


class BleDeviceStub(DeviceTransport):
    """
    In-memory Bluetooth Low Energy transport stub for development and testing.
    Simulates discovery, connection, audio streaming, and push-to-talk button events.
    """

    def __init__(self, simulated_devices: Optional[List[DeviceInfo]] = None):
        self._state = ConnectionState.DISCONNECTED
        self._connected_device: Optional[DeviceInfo] = None
        self._simulated_devices = simulated_devices or [
            DeviceInfo(
                device_id="ble:spk-toy-001",
                name="Speakaboo Toy (Puff)",
                rssi=-54,
                battery_percentage=92,
                firmware_version="1.0.2-ble",
            ),
            DeviceInfo(
                device_id="ble:spk-toy-002",
                name="Speakaboo Toy (Reggie)",
                rssi=-78,
                battery_percentage=65,
                firmware_version="1.0.1-ble",
            ),
        ]
        self._incoming_audio_queue: asyncio.Queue = asyncio.Queue()
        self._outgoing_audio_log: List[bytes] = []
        self._events: List[DeviceEvent] = []
        self._led_color: str = "#000000"
        self._volume: int = 80

    @property
    def state(self) -> ConnectionState:
        return self._state

    @property
    def connected_device(self) -> Optional[DeviceInfo]:
        return self._connected_device

    async def scan(self, timeout_seconds: float = 0.1) -> List[DeviceInfo]:
        self._state = ConnectionState.SCANNING
        await asyncio.sleep(0.01)  # Simulate brief scan delay
        self._state = ConnectionState.DISCONNECTED
        return list(self._simulated_devices)

    async def connect(self, device_id: str) -> bool:
        target = next((d for d in self._simulated_devices if d.device_id == device_id), None)
        if not target:
            self._state = ConnectionState.ERROR
            return False

        self._state = ConnectionState.CONNECTING
        await asyncio.sleep(0.01)
        self._state = ConnectionState.CONNECTED
        self._connected_device = target
        target.is_paired = True
        self._events.append(
            DeviceEvent(
                event_type=DeviceEventType.STATE_CHANGED,
                payload={"state": ConnectionState.CONNECTED.value, "device_id": device_id},
            )
        )
        return True

    async def disconnect(self) -> None:
        if self._connected_device:
            dev_id = self._connected_device.device_id
            self._connected_device = None
            self._state = ConnectionState.DISCONNECTED
            self._events.append(
                DeviceEvent(
                    event_type=DeviceEventType.STATE_CHANGED,
                    payload={"state": ConnectionState.DISCONNECTED.value, "device_id": dev_id},
                )
            )

    async def send_audio_chunk(self, chunk: bytes) -> bool:
        if self._state != ConnectionState.CONNECTED:
            return False
        self._outgoing_audio_log.append(chunk)
        return True

    async def receive_audio_chunk(self) -> Optional[bytes]:
        if self._state != ConnectionState.CONNECTED:
            return None
        if self._incoming_audio_queue.empty():
            return None
        return await self._incoming_audio_queue.get()

    async def simulate_microphone_audio(self, pcm_bytes: bytes) -> None:
        """Helper to inject simulated microphone audio from the physical toy."""
        await self._incoming_audio_queue.put(pcm_bytes)

    async def simulate_button_press(self) -> None:
        """Helper to simulate child pressing the physical talk button."""
        self._events.append(
            DeviceEvent(
                event_type=DeviceEventType.BUTTON_PRESSED,
                payload={"button": "push_to_talk"},
            )
        )

    async def simulate_button_release(self) -> None:
        """Helper to simulate child releasing the physical talk button."""
        self._events.append(
            DeviceEvent(
                event_type=DeviceEventType.BUTTON_RELEASED,
                payload={"button": "push_to_talk"},
            )
        )

    async def send_command(self, command: str, params: Optional[Dict[str, Any]] = None) -> bool:
        if self._state != ConnectionState.CONNECTED:
            return False
        params = params or {}
        if command == "set_led":
            self._led_color = params.get("color", "#FFFFFF")
        elif command == "set_volume":
            self._volume = int(params.get("volume", 80))
        return True

    async def get_events(self) -> List[DeviceEvent]:
        events = list(self._events)
        self._events.clear()
        return events
