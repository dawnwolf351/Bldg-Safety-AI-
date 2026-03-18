from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flasgger import Swagger
from config import Config

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # DB 및 Swagger 도구 세팅
    db.init_app(app)
    Swagger(app)

    # 잠시 후 여기에 devices 부서(Blueprint)를 등록할 예정입니다.

    return app