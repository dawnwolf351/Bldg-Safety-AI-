"""
실제 DB 연결 전까지 사용할 임시 데이터 저장소
"""
from app.extensions import bcrypt

# 메모리에 저장될 유저 목록
# 구조: {"email": {"email", "password_hash", "name", "role"}}
users = {}

def add_user(email, password, name, role='viewer'):
    if email in users:
        return False, "이미 존재하는 이메일입니다."
    
    users[email] = {
        "email": email,
        "password_hash": bcrypt.generate_password_hash(password).decode('utf-8'),
        "name": name,
        "role": role
    }
    return True, None

def get_user(email):
    return users.get(email)

def check_password(email, password):
    user = get_user(email)
    if not user:
        return False
    return bcrypt.check_password_hash(user['password_hash'], password)
