from zigpy.profiles import zha
from zhaquirks.builder import QuirkBuilder

(
    QuirkBuilder("_TZ3000_oknvq1nn", "TS0001")
    .replaces_endpoint(1, device_type=zha.DeviceType.ON_OFF_OUTPUT)
    .add_to_registry()
)
