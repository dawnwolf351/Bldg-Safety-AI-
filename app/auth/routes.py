from flask import request
from flask_restx import Namespace, Resource, fields
from werkzeug.security import check_password_hash
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
    get_jwt
)
from app.users.models import User

# Namespace 생성
auth_ns = Namespace('Auth', description='사용자 인증 및 토큰 발급 API')

# Swagger 입력 양식 정의
login_model = auth_ns.model('LoginInput', {
    'email': fields.String(required=True, description='이메일', example='admin@test.com'),
    'password': fields.String(required=True, description='비밀번호', example='supersecret123')
})


@auth_ns.route('/login')
class Login(Resource):

    @auth_ns.expect(login_model)
    @auth_ns.doc(responses={200: '로그인 성공', 400: '입력 오류', 401: '인증 실패'})
    def post(self):
        """사용자 로그인 및 JWT 토큰 세트 발급 (레벨 정보 포함)"""
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return {"error": "이메일과 비밀번호를 모두 입력해주세요."}, 400

        user = User.query.filter_by(email=email).first()

        if not user or not check_password_hash(user.password_hash, password):
            return {"error": "이메일이나 비밀번호가 올바르지 않습니다."}, 401

        # 사용자의 직급 이름과 숫자 레벨을 가져옵니다.
        role_name = user.role.role_name if user.role else "ROLE_USER"
        role_level = user.role.level if user.role else 1

        # 토큰 내부에 직급과 레벨을 모두 심습니다.
        additional_claims = {
            "role": role_name,
            "level": role_level
        }

        # Access Token & Refresh Token 발급
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

        return {
            "message": f"{user.name}님 환영합니다!",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "role": role_name,
            "level": role_level  # 👈 앱에서도 바로 알 수 있게 응답에 추가
        }, 200


@auth_ns.route('/refresh')
class Refresh(Resource):

    @auth_ns.doc(responses={200: '새 Access Token 발급 성공', 401: '인증 실패'}, security='Bearer')
    @jwt_required(refresh=True)
    def post(self):
        """만료된 Access Token 재발급 (레벨 정보 유지)"""
        current_user_id = get_jwt_identity()

        # 리프레시 토큰에서 직급과 레벨 정보를 다시 꺼냅니다.
        claims = get_jwt()
        current_role = claims.get("role")
        current_level = claims.get("level")

        # 새 액세스 토큰에도 기존 레벨 정보를 그대로 복사합니다.
        new_claims = {
            "role": current_role,
            "level": current_level
        }
        new_access_token = create_access_token(identity=current_user_id, additional_claims=new_claims)

        return {
            "message": "시간이 연장되었습니다!",
            "access_token": new_access_token
        }, 200