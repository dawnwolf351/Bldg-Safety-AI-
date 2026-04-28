from app import db
from datetime import datetime

class JetsonDevice(db.Model):
    __tablename__ = 'jetson_devices'

    # 컬럼(속성) 정의
    id = db.Column(db.Integer, primary_key=True)
    mac_address = db.Column(db.String(17), nullable=False, unique=True)     # 🌟 핵심: MAC 주소 (예: 00:1A:2B:3C:4D:5E)
    device_name = db.Column(db.String(100), nullable=False)                 # 장치 이름 (예: 1공장 입구)
    last_known_ip = db.Column(db.String(50), nullable=True)                 # 마지막으로 연결됐던 IP 주소 (참고용)
    location = db.Column(db.String(255), nullable=True)                     # 상세 설치 위치
    is_online = db.Column(db.Boolean, default=False)                        # 현재 소켓이 연결되어 있는지 여부
    last_connected_at = db.Column(db.DateTime, default=datetime.utcnow)     # 마지막으로 통신한 시간
    created_at = db.Column(db.DateTime, default=datetime.utcnow)            # DB 최초 등록일

    # users 테이블의 id를 바라보는 꼬리표 (관리자가 기기를 먼저 등록할 수 있으니 nullable=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "mac_address": self.mac_address,
            "device_name": self.device_name,
            "last_known_ip": self.last_known_ip,
            "location": self.location,
            "is_online": self.is_online,
            "last_connected_at": self.last_connected_at.strftime("%Y-%m-%d %H:%M:%S") if self.last_connected_at else None,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None
        }