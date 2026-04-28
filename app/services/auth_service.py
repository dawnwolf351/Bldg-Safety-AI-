import jwt
import datetime
from flask import current_app
from app.extensions import db, bcrypt
from app.models.user import User

class AuthService:
    @staticmethod
    def register(email, password, name, role='viewer'):
        # 이미 존재하는 이메일인지 확인
        if User.query.filter_by(email=email).first():
            return False, "이미 존재하는 이메일입니다."
        
        # 새 유저 생성 및 DB에 저장
        new_user = User(
            email=email,
            password_hash=bcrypt.generate_password_hash(password).decode('utf-8'),
            name=name,
            role=role
        )
        db.session.add(new_user)
        db.session.commit()
        return True, None

    @staticmethod
    def _create_access_token(user):
        """Access Token 생성 (5분 만료)"""
        expires = current_app.config.get('JWT_ACCESS_TOKEN_EXPIRES', 300)
        payload = {
            'user_id': user.id,
            'email': user.email,
            'role': user.role,
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
