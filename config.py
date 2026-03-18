class Config:
    # 도커에 띄워둔 MariaDB 연결 정보 (포트 3307)
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://root:1234@127.0.0.1:3307/safety_db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JSON_AS_ASCII = False