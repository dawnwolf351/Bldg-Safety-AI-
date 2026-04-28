from flask import Flask, jsonify, request
from flask_cors import CORS
from config import Config
from app.extensions import bcrypt, db, api
from app.routes.auth import auth_ns
from app.routes.devices import devices_ns
from app.routes.users import users_ns

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # 한글 유니코드 변환 방지
    app.json.ensure_ascii = False

    # 확장 초기화
    db.init_app(app)
    bcrypt.init_app(app)
    api.init_app(app)
    CORS(app)  # 외부 IP에서 API 호출 허용

    # 네임스페이스 등록
    api.add_namespace(auth_ns, path='/api/auth')
    api.add_namespace(devices_ns, path='/api/devices')
    api.add_namespace(users_ns, path='/api/users')

    # DB 모델 임포트 및 테이블 자동 생성
    with app.app_context():
        from app.models.role import Role
        from app.models.user import User
        from app.models.device import JetsonDevice
        db.create_all()

    # 기본 루트 경로 (접속 확인용)
    @app.route('/')
    def index():
        return jsonify({
            "status": "online",
            "message": "Safe Guard AI Server is running!",
            "public_ip": "121.144.215.82"
        }), 200

    # 모든 요청에 대해 로그를 남김 (디버깅용)
    @app.before_request
    def log_request_info():
        print(f"--- [REQUEST] {request.method} {request.url} ---")
        print(f"Headers: {dict(request.headers)}")
        if request.is_json:
            print(f"Body: {request.get_json()}")
        print("---------------------------------------")

    return app

