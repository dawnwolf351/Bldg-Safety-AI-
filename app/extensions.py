from flask_bcrypt import Bcrypt
from flask_sqlalchemy import SQLAlchemy
from flask_restx import Api

bcrypt = Bcrypt()
db = SQLAlchemy()
api = Api(
    title='Swagger API',
    version='1.0',
    description='Swagger API 문서',
    doc='/swagger'
)
