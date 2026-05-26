from datetime import datetime
from app import db


class DeviceState(db.Model):
    __tablename__ = 'device_states'

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    device_id = db.Column(db.Integer, db.ForeignKey('jetson_devices.device_id'), nullable=False)

    recorded_at = db.Column(db.DateTime, default=datetime.utcnow, index=True, nullable=False)

    cpu_usage = db.Column(db.Float, nullable=False)
    gpu_usage = db.Column(db.Float, nullable=False)
    ram_usage = db.Column(db.Float, nullable=False)
    disk_usage = db.Column(db.Float, nullable=False)

    temperature = db.Column(db.Float, nullable=False)
    is_overheated = db.Column(db.Boolean, default=False, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "device_id": self.device_id,
            "recorded_at": self.recorded_at.strftime('%Y-%m-%d %H:%M:%S'),
            "cpu_usage": self.cpu_usage,
            "gpu_usage": self.gpu_usage,
            "ram_usage": self.ram_usage,
            "disk_usage": self.disk_usage,
            "temperature": self.temperature,
            "is_overheated": self.is_overheated
        }