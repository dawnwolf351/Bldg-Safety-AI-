import jwt
import datetime
from functools import wraps
from flask import current_app, request
from app.extensions import db, bcrypt
from app.models.user import User
from app.models.role import Role


def token_required(f):
    """JWT Access Token 검증 데코레이터.
    인증된 사용자 객체를 current_user로 주입합니다."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')

        if not auth_header:
            return {"error": "토큰이 필요합니다."}, 401

        try:
            # "Bearer <token>" 형식에서 토큰 추출
            token = auth_header.split(" ")[1] if " " in auth_header else auth_header
        except IndexError:
            return {"error": "유효하지 않은 토큰 형식입니다."}, 401

        payload, error = AuthService.decode_token(token)
        if error:
            return {"error": error}, 401

        current_user = User.query.get(payload['user_id'])
        if not current_user:
            return {"error": "사용자를 찾을 수 없습니다."}, 401

        return f(*args, current_user=current_user, **kwargs)
    return decorated


class AuthService:
    @staticmethod
    def register(email, password, name, role_name='ROLE_USER'):
        # 이미 존재하는 이메일인지 확인
        if User.query.filter_by(email=email).first():
            return False, "이미 존재하는 이메일입니다."

        # 직급 조회
        role = Role.query.filter_by(role_name=role_name).first()
        if not role:
            # 기본값으로 ROLE_USER 사용
            role = Role.query.filter_by(role_name='ROLE_USER').first()
            if not role:
                return False, "기본 직급(ROLE_USER)이 아직 생성되지 않았습니다. create_admin.py를 먼저 실행하세요."

        # 새 유저 생성 및 DB에 저장
        new_user = User(
            email=email,
            password_hash=bcrypt.generate_password_hash(password).decode('utf-8'),
            name=name,
            role_id=role.id
        )
        db.session.add(new_user)
        db.session.commit()
        return True, None

    @staticmethod
    def _create_access_token(user):
        """Access Token 생성 (5분 만료) — role/level 정보 포함"""
        expires = current_app.config.get('JWT_ACCESS_TOKEN_EXPIRES', 300)

        # 사용자의 직급/레벨 정보 가져오기
        role_name = user.role_info.role_name if user.role_info else "ROLE_USER"
        role_level = user.role_info.level if user.role_info else 1

        payload = {
            'user_id': user.id,
            'email': user.email,
            'role': role_name,
            'level': role_level,
            'type': 'access',
            'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=expires)
        }
        return jwt.encode(payload, current_app.config['SECRET_KEY'], algorithm='HS256')

    @staticmethod
    def _create_refresh_token(user):
        """Refresh Token 생성 (30분 만료)"""
        expires = current_app.config.get('JWT_REFRESH_TOKEN_EXPIRES', 1800)
        payload = {
            'user_id': user.id,
            'email': user.email,
            'type': 'refresh',
            'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=expires)
        }
        return jwt.encode(payload, current_app.config['JWT_REFRESH_SECRET_KEY'], algorithm='HS256')

    @staticmethod
    def login(email, password):
        user = User.query.filter_by(email=email).first()

        if not user or not bcrypt.check_password_hash(user.password_hash, password):
            return None, "이메일 또는 비밀번호가 올바르지 않습니다."

        # Access Token + Refresh Token 동시 발급
        access_token = AuthService._create_access_token(user)
        refresh_token = AuthService._create_refresh_token(user)

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": user.to_dict()
        }, None

    @staticmethod
    def refresh_access_token(refresh_token_str, extend=False):
        """
        Refresh Token으로 새 Access Token 발급.

        Args:
            refresh_token_str: 클라이언트가 보낸 refresh token 문자열
            extend: True이면 refresh token도 새로 발급 (30분 리셋)

        Returns:
            (result_dict, error_message)
        """
        # Refresh Token 검증
        payload, error = AuthService.decode_refresh_token(refresh_token_str)
        if error:
            return None, error

        # 토큰 타입 검증
        if payload.get('type') != 'refresh':
            return None, "유효하지 않은 토큰 타입입니다."

        # 유저 조회
        user = User.query.get(payload['user_id'])
        if not user:
            return None, "사용자를 찾을 수 없습니다."

        # 새 Access Token 발급
        result = {
            "access_token": AuthService._create_access_token(user)
        }

        # extend=True이면 Refresh Token도 새로 발급 (30분 리셋)
        if extend:
            result["refresh_token"] = AuthService._create_refresh_token(user)

        return result, None

    @staticmethod
    def decode_token(token):
        """Access Token을 검증하고 페이로드를 반환"""
        try:
            payload = jwt.decode(
                token,
                current_app.config['SECRET_KEY'],
                algorithms=['HS256']
            )
            if payload.get('type') != 'access':
                return None, "유효하지 않은 토큰 타입입니다."
            return payload, None
        except jwt.ExpiredSignatureError:
            return None, "토큰이 만료되었습니다."
        except jwt.InvalidTokenError:
            return None, "유효하지 않은 토큰입니다."

    @staticmethod
    def decode_refresh_token(token):
        """Refresh Token을 검증하고 페이로드를 반환"""
        try:
            payload = jwt.decode(
                token,
                current_app.config['JWT_REFRESH_SECRET_KEY'],
                algorithms=['HS256']
            )
            return payload, None
        except jwt.ExpiredSignatureError:
            return None, "리프레시 토큰이 만료되었습니다. 다시 로그인해주세요."
        except jwt.InvalidTokenError:
            return None, "유효하지 않은 리프레시 토큰입니다."

