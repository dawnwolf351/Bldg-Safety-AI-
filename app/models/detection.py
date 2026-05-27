from datetime import datetime
from app.extensions import db


# ==========================================
# 1. 탐지 데이터 테이블 (원천 데이터)
# ==========================================
class Detection(db.Model):
    __tablename__ = 'detections'

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    camera_id = db.Column(db.Integer, nullable=False)  # (주의) 기존 장비/카메라 테이블의 외래키로 매핑 필요
    detected_at = db.Column(db.DateTime, default=datetime.utcnow, index=True, nullable=False)
    class_id = db.Column(db.Integer, nullable=False)  # 0: Crack, 1: Spalling
    confidence = db.Column(db.Float, nullable=False)  # 0.0 ~ 1.0

    # Bounding Box는 JSON 배열을 문자열로 직렬화하여 저장하거나 JSON 타입 사용
    bbox = db.Column(db.String(255), nullable=True)  # 예: "[100, 200, 150, 250]"
    size_px = db.Column(db.Float, nullable=True)  # 면적 또는 두께
    image_path = db.Column(db.String(500), nullable=True)

    # 1:1 관계 (하나의 탐지는 하나의 위험도 평가를 가짐)
    risk_assessment = db.relationship('RiskAssessment', backref='detection', uselist=False,
                                      cascade="all, delete-orphan")


# ==========================================
# 2. 위험도 평가 테이블 (비즈니스 로직)
# ==========================================
class RiskAssessment(db.Model):
    __tablename__ = 'risk_assessments'

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    detection_id = db.Column(db.BigInteger, db.ForeignKey('detections.id'), nullable=False)
    assessed_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    risk_score = db.Column(db.Float, nullable=False)
    risk_level = db.Column(db.String(20), index=True, nullable=False)  # LOW, MEDIUM, HIGH, CRITICAL
    is_complex = db.Column(db.Boolean, default=False, nullable=False)  # 복합 결함 여부

    # 1:N 관계 (하나의 위험도 평가로 인해 슬랙, 대시보드 등 여러 알림이 발생할 수 있음)
    alerts = db.relationship('Alert', backref='risk_assessment', lazy=True, cascade="all, delete-orphan")


# ==========================================
# 3. 알림 이력 테이블 (액션 및 조치)
# ==========================================
class Alert(db.Model):
    __tablename__ = 'alerts'

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    risk_id = db.Column(db.BigInteger, db.ForeignKey('risk_assessments.id'), nullable=False)

    channel = db.Column(db.String(50), nullable=False)  # 예: 'mqtt', 'slack', 'dashboard'
    status = db.Column(db.String(20), default='SENT', nullable=False)  # 'SENT', 'FAIL', 'ACK'

    sent_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    ack_at = db.Column(db.DateTime, nullable=True)  # 관리자 확인 시각
