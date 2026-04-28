from flask import Flask, Blueprint
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from datetime import timedelta
from config import Config
# 🌟 1. Flasgger 대신 RESTX 불러오기!
from flask_restx import Api

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # 한글 유니코드 변환을 막아줍니다!
    app.json.ensure_ascii = False

    # 2. JWT 암호화 키 설정 (출입증 위조 방지용 비밀번호)
    app.config['JWT_SECRET_KEY'] = 'super-secret-capstone-key-2026'

    # 🌟 Access Token은 10분, REFRESH_TOKEN은 1시간
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(minutes=10)
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(hours=1)

    # 3. 앱에 JWT 기계 전원 ON!
    jwt = JWTManager(app)

    db.init_app(app)

    # 🌟 4. RESTX용 Swagger 보안(자물쇠) 세팅
    authorizations = {
        'Bearer': {
            'type': 'apiKey',
            'in': 'header',
            'name': 'Authorization',
            'description': "JWT 토큰을 입력하세요. (예: Bearer eyJhbGci...)"
        }
    }

    # 🌟 5. RESTX API 객체 생성 및 Blueprint 연결
    # 이제 모든 API는 기본적으로 '/api' 주소 안에서 관리됩니다.
    api_bp = Blueprint('api', __name__, url_prefix='/api')
    api = Api(
        api_bp,
        version='1.0',
        title='캡스톤 API',
        description='젯슨 나노 화재/균열 감지 백엔드 서버',
        authorizations=authorizations,
        security='Bearer' # 모든 API에 기본으로 자물쇠 모양 띄우기
    )

    with app.app_context():
        # DB 테이블들을 한 번에 묶어서 생성하도록 모델 추가
        from app.users import models
        from app.devices import models
        db.create_all()

    # 🌟 6. 새로 바꾼 Auth 라우터(네임스페이스) 등록
    from app.auth.routes import auth_ns
    api.add_namespace(auth_ns, path='/auth')

    # 🌟 7. 드디어 완벽해진 나머지 API들도 Swagger(api)에 꽂아줍니다!
    from app.users.routes import users_ns
    from app.devices.routes import devices_ns

    api.add_namespace(users_ns, path='/users')
    api.add_namespace(devices_ns, path='/devices')

    # 최종 API Blueprint 등록!
    app.register_blueprint(api_bp)

    return app