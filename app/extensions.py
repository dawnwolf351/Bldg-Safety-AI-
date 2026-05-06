from flask_bcrypt import Bcrypt
from flask_sqlalchemy import SQLAlchemy
from flask_restx import Api
import redis

bcrypt = Bcrypt()
db = SQLAlchemy()
api = Api(
    title='Swagger API',
    version='1.0',
    description='Swagger API 문서',
    doc='/swagger'
)

#Docker에 띄워둔 Redis와 연결 (기본 포트 6379)
jwt_redis_blocklist = redis.StrictRedis(
    host='localhost',
    port=6379,
    db=0,
    decode_responses=True
)