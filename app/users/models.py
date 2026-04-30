from app import db
from datetime import datetime


#  1. 권한(계급장) 테이블
class Role(db.Model):
    __tablename__ = 'roles'

    id = db.Column(db.Integer, primary_key=True)
    role_name = db.Column(db.String(50), unique=True, nullable=False)
    description = db.Column(db.String(255), nullable=True)
    level = db.Column(db.Integer, nullable=False, default=1)

    #  드디어 주석 해제! (Role과 User의 완벽한 연결)
    users = db.relationship('User', backref='role', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "role_name": self.role_name,
            "description": self.description,
            "level" : self.level
        }


# 2. 사용자(인사팀 장부) 테이블
class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)  # 비밀번호는 나중에 암호화 저장!
    name = db.Column(db.String(50), nullable=False)

    #  핵심: Role 테이블의 id를 가져와서 내 직급으로 삼습니다.
    role_id = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # 내가 담당하는 젯슨 기기 목록과의 연결고리
    devices = db.relationship('JetsonDevice', backref='owner', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            # 연결된 Role 테이블에서 권한 이름을 바로 꺼내옵니다!
            "role_name": self.role.role_name if self.role else None
        }