from flask import request
# RESTX 전용 도구들 불러오기
from flask_restx import Namespace, Resource, fields
from werkzeug.security import generate_password_hash
# 추가됨: get_jwt_identity (유저 본인 삭제 방지용)
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from app import db
from app.users.models import User, Role

# Blueprint 대신 Namespace 생성
users_ns = Namespace('Users', description='사용자 관리 API')

# Swagger 문서에 띄울 '입력 양식(틀)'을 코드로 정의
register_model = users_ns.model('RegisterInput', {
    'email': fields.String(required=True, description='이메일', example='newuser@test.com'),
    'password': fields.String(required=True, description='비밀번호', example='supersecret123'),
    'name': fields.String(required=True, description='이름', example='신입연구원'),
    'role_name': fields.String(description='직급 (기본값: ROLE_USER)', example='ROLE_USER')
})

# 유저 정보 수정용 입력 양식 추가
user_update_model = users_ns.model('UserUpdateInput', {
    'name': fields.String(description='변경할 이름', example='수석연구원'),
    'password': fields.String(description='변경할 비밀번호', example='newsecret123'),
    'role_name': fields.String(description='변경할 직급', example='ROLE_ADMIN')
})


# 회원가입 API (함수 대신 클래스 사용)
@users_ns.route('/register')
class Register(Resource):

    @users_ns.expect(register_model)  # Swagger 입력창 생성
    @users_ns.doc(
        responses={201: '회원가입 성공', 400: '입력값 오류 또는 중복', 401: '인증 실패', 403: '권한 없음'},
        security='Bearer'  # 이 API는 자물쇠(인증)가 필요함을 명시!
    )
    @jwt_required()
    def post(self):
        """새로운 사용자 회원가입 API (권한 레벨 기반 차등 생성)"""

        # 내 토큰에서 레벨 확인 (기본값 1)
        current_level = get_jwt().get("level", 1)

        # 일반 유저(레벨 1)는 아무도 만들 수 없음
        if current_level < 2:
            return {"error": "접근 거부: 일반 유저는 계정을 생성할 수 없습니다."}, 403

        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        role_name = data.get('role_name', 'ROLE_USER')  # 만들려는 타겟 직급

        if not email or not password or not name:
            return {"error": "이메일, 비밀번호, 이름을 모두 입력해주세요."}, 400

        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            return {"error": "이미 등록된 이메일입니다."}, 400

        # 만들려는 직급(Role)이 DB에 존재하는지, 레벨이 몇인지 확인
        target_role = Role.query.filter_by(role_name=role_name).first()
        if not target_role:
            return {"error": f"'{role_name}'(은)는 존재하지 않는 직급입니다."}, 400

        # API로는 최고관리자(레벨 3)를 절대 만들 수 없음
        if target_role.level == 3:
            return {"error": "보안 위반: 최고관리자 계정은 API를 통해 생성할 수 없습니다."}, 403

        # 핵심 방어 로직: 나보다 높거나 같은 등급은 만들 수 없음!
        if current_level <= target_role.level:
            return {"error": f"접근 거부: 본인(레벨 {current_level})보다 높거나 같은 등급(레벨 {target_role.level})은 생성할 수 없습니다."}, 403

        # 새 유저 생성 및 암호화
        new_user = User(
            email=email,
            password_hash=generate_password_hash(password),
            name=name,
            role_id=target_role.id
        )

        db.session.add(new_user)
        db.session.commit()

        return {"message": f"{name}님 환영합니다! {target_role.description} 권한으로 가입되었습니다."}, 201


# [유저 수정 & 삭제 API] 주소: /<user_id>
@users_ns.route('/<int:user_id>')
@users_ns.param('user_id', '수정/삭제할 유저의 고유 ID 번호')
class UserDetail(Resource):

    @users_ns.expect(user_update_model)
    @users_ns.doc(security='Bearer', responses={200: '수정 성공', 400: '잘못된 요청', 403: '권한 없음', 404: '유저 없음'})
    @jwt_required()
    def put(self, user_id):
        """특정 유저 정보 수정 (최고관리자 레벨 3 전용)"""
        # 레벨 3(최고관리자) 미만이면 거부!
        if get_jwt().get("level", 1) < 3:
            return {"error": "접근 거부: 유저 정보 수정은 최고관리자(레벨 3)만 가능합니다."}, 403

        target_user = User.query.get_or_404(user_id)
        data = request.get_json()

        # 데이터가 들어온 항목만 선택적으로 업데이트합니다.
        if 'name' in data:
            target_user.name = data['name']
        if 'password' in data:
            target_user.password_hash = generate_password_hash(data['password'])
        if 'role_name' in data:
            new_role = Role.query.filter_by(role_name=data['role_name']).first()
            if not new_role:
                return {"error": f"'{data['role_name']}'(은)는 존재하지 않는 직급입니다."}, 400

            # API를 통해 일반 계정을 최고관리자로 승급시키는 것도 막아둡니다 (보안 강화)
            if new_role.level == 3:
                return {"error": "보안 위반: 일반 계정을 최고관리자로 승급시킬 수 없습니다."}, 403

            target_user.role_id = new_role.id

        db.session.commit()
        return {"message": f"[{target_user.email}] 계정의 정보가 성공적으로 수정되었습니다."}, 200

    @users_ns.doc(security='Bearer', responses={200: '삭제 성공', 400: '본인 삭제 시도', 403: '권한 없음'})
    @jwt_required()
    def delete(self, user_id):
        """특정 유저 삭제 (최고관리자 레벨 3 전용)"""
        # 레벨 3(최고관리자) 미만이면 거부!
        if get_jwt().get("level", 1) < 3:
            return {"error": "접근 거부: 유저 삭제는 최고관리자(레벨 3)만 가능합니다."}, 403

        current_user_id = int(get_jwt_identity())
        target_user = User.query.get_or_404(user_id)

        # 자폭 방지 장치: 최고관리자가 실수로 자기 자신을 삭제하는 것을 막습니다.
        if current_user_id == target_user.id:
            return {"error": "보안 위반: 현재 로그인된 최고관리자 본인의 계정은 스스로 삭제할 수 없습니다."}, 400

        db.session.delete(target_user)
        db.session.commit()

        return {"message": f"유저({target_user.email})가 시스템에서 완전히 삭제되었습니다."}, 200