from flask import request
from flask_restx import Namespace, Resource, fields
from app.services.auth_service import AuthService
from app.extensions import db
from app.utils.error_codes import AUTH_ERRORS, TOKEN_ERRORS, apply_error_responses
from http import HTTPStatus
import traceback


# API 네임스페이스 정의 (기존 Blueprint 역할)
auth_ns = Namespace('auth', description='인증 관련 API')

# --- [Swagger 데이터 모델 정의 - backend 스타일] ---

# 1. 사용자 정보 모델 (기본)
user_model = auth_ns.model('UserResponse', {
    'id': fields.Integer(description='사용자 고유 ID', example=1),
    'email': fields.String(description='이메일 주소', example='test@naver.com'),
    'name': fields.String(description='사용자 이름', example='홍길동'),
    'role': fields.String(description='사용자 역할', example='viewer'),
    'created_at': fields.String(description='가입 일시', example='2024-03-26T12:00:00')
})

# 2. 토큰 및 사용자 정보 포함 모델 (로그인 성공 시)
login_success_model = auth_ns.model('LoginResponse', {
    'message': fields.String(description='성공 메시지', example='Login successful'),
    'access_token': fields.String(description='JWT 액세스 토큰 (5분 만료)'),
    'refresh_token': fields.String(description='JWT 리프레시 토큰 (30분 만료)'),
    'user': fields.Nested(user_model, description='사용자 상세 정보')
})

# 3. 에러 응답 모델
error_model = auth_ns.model('ErrorResponse', {
    'error': fields.String(description='에러 메시지', example='Missing fields')
})

# 4. 요청 모델 (상세 설명 및 예시 추가)
login_request = auth_ns.model('LoginRequest', {
    'email': fields.String(required=True, description='이메일 주소', example='test@naver.com'),
    'password': fields.String(required=True, description='비밀번호', example='1234')
})

signup_request = auth_ns.model('RegisterRequest', {
    'email': fields.String(required=True, description='이메일 주소', example='test@naver.com'),
    'password': fields.String(required=True, description='비밀번호', example='1234'),
    'name': fields.String(required=True, description='이름', example='홍길동'),
    'role': fields.String(description='역할 (viewer/admin)', default='viewer', example='viewer')
})

# 5. 리프레시 토큰 요청/응답 모델
refresh_request = auth_ns.model('RefreshRequest', {
    'refresh_token': fields.String(required=True, description='리프레시 토큰'),
    'extend': fields.Boolean(description='세션 연장 여부 (true: 30분 리셋)', default=False, example=True)
})

refresh_response = auth_ns.model('RefreshResponse', {
    'message': fields.String(description='성공 메시지', example='Token refreshed'),
    'access_token': fields.String(description='새 JWT 액세스 토큰 (5분 만료)'),
    'refresh_token': fields.String(description='새 JWT 리프레시 토큰 (extend=true 시에만, 30분 리셋)')
})

# 6. 로그아웃 응답 모델
logout_response = auth_ns.model('LogoutResponse', {
    'message': fields.String(description='로그아웃 메시지', example='로그아웃 되었습니다.')
})

# --- [API 리소스 정의] ---

@auth_ns.route('/register')
class RegisterResource(Resource):
    @auth_ns.doc(id='register_user', description='새로운 사용자를 등록합니다.')
    @auth_ns.expect(signup_request)
    @auth_ns.response(code=201, description='회원가입 성공', model=auth_ns.model('SuccessResponse', {
        'message': fields.String(example='User registered successfully')
    }))
    @apply_error_responses(auth_ns, AUTH_ERRORS, error_model)
    def post(self):
        """사용자 회원가입"""
        try:
            data = request.get_json(silent=True)
            email = data.get('email')
            password = data.get('password')
            name = data.get('name')
            role = data.get('role', 'viewer')

            if not email or not password or not name:
                return {"error": "Missing fields"}, HTTPStatus.BAD_REQUEST

            success, message = AuthService.register(email, password, name, role)
            if not success:
                return {"error": message}, HTTPStatus.CONFLICT

            return {"message": "User registered successfully"}, HTTPStatus.CREATED

        except Exception as e:
            db.session.rollback()
            print(f"RegisterAPI ERROR: {e}")
            traceback.print_exc()
            return {"error": "서버 내부 오류"}, HTTPStatus.INTERNAL_SERVER_ERROR

@auth_ns.route('/login')
class LoginResource(Resource):
    @auth_ns.doc(id='login_user', description='이메일과 비밀번호로 로그인하여 Access Token과 Refresh Token을 발급받습니다.')
    @auth_ns.expect(login_request)
    @auth_ns.marshal_with(login_success_model, code=200)
    @apply_error_responses(auth_ns, AUTH_ERRORS, error_model)
    def post(self):
        """사용자 로그인"""
        try:
            data = request.get_json(silent=True)
            email = data.get('email')
            password = data.get('password')

            result, error = AuthService.login(email, password)

            if error:
                return {"error": error}, HTTPStatus.UNAUTHORIZED

            return {
                "message": "Login successful",
                **result
            }, HTTPStatus.OK

        except Exception as e:
            db.session.rollback()
            print(f"LoginAPI ERROR: {e}")
            traceback.print_exc()
            return {"error": "서버 내부 오류"}, HTTPStatus.INTERNAL_SERVER_ERROR

@auth_ns.route('/refresh')
class RefreshResource(Resource):
    @auth_ns.doc(id='refresh_token', description=(
        'Refresh Token으로 새 Access Token을 발급받습니다.\n\n'
        '- **extend=false** (기본): Access Token만 갱신. 세션 타이머(30분)는 유지됩니다.\n'
        '- **extend=true**: Access Token + Refresh Token 모두 갱신. 세션 30분이 리셋됩니다.\n\n'
        '새로고침이나 "시간연장" 버튼 클릭 시 extend=true로 호출하세요.'
    ))
    @auth_ns.expect(refresh_request)
    @auth_ns.response(code=200, description='토큰 갱신 성공', model=refresh_response)
    @apply_error_responses(auth_ns, TOKEN_ERRORS, error_model)
    def post(self):
        """토큰 갱신 (세션 연장)"""
        try:
            data = request.get_json(silent=True)
            refresh_token = data.get('refresh_token')
            extend = data.get('extend', False)

            if not refresh_token:
                return {"error": "refresh_token이 필요합니다."}, HTTPStatus.BAD_REQUEST

            result, error = AuthService.refresh_access_token(refresh_token, extend=extend)

            if error:
                return {"error": error}, HTTPStatus.UNAUTHORIZED

            return {
                "message": "Token refreshed",
                **result
            }, HTTPStatus.OK

        except Exception as e:
            print(f"RefreshAPI ERROR: {e}")
            traceback.print_exc()
            return {"error": "서버 내부 오류"}, HTTPStatus.INTERNAL_SERVER_ERROR

@auth_ns.route('/logout')
class LogoutResource(Resource):
    @auth_ns.doc(id='logout_user', description='로그아웃 처리. 클라이언트에서 토큰을 삭제합니다.')
    @auth_ns.response(code=200, description='로그아웃 성공', model=logout_response)
    def post(self):
        """사용자 로그아웃"""
        return {"message": "로그아웃 되었습니다."}, HTTPStatus.OK
