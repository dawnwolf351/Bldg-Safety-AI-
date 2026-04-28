from flask import request
# 1. RESTX 전용 도구 불러오기
from flask_restx import Namespace, Resource, fields
from flask_jwt_extended import jwt_required, get_jwt
from app import db
from app.devices.models import JetsonDevice

# 2. Blueprint 대신 Namespace 생성
devices_ns = Namespace('Devices', description='기기 관리 API')

# 3. Swagger 문서에 띄울 '입력 양식(틀)' 2개 정의 (등록용, 수정용)
device_register_model = devices_ns.model('DeviceRegister', {
    'mac_address': fields.String(required=True, description='기기 MAC 주소', example='AA:BB:CC:DD:EE:11'),
    'device_name': fields.String(required=True, description='기기 이름', example='1공장 정문 카메라'),
    'location': fields.String(description='설치 위치', example='부산공장 A동')
})

device_update_model = devices_ns.model('DeviceUpdate', {
    'device_name': fields.String(description='기기 이름', example='1공장 정문 카메라'),
    'location': fields.String(description='설치 위치', example='A동 1층')
})


# [목록 조회 & 등록 API] 주소: /
@devices_ns.route('/')
class DeviceList(Resource):

    @devices_ns.doc(security='Bearer', responses={200: '성공'})
    @jwt_required()
    def get(self):
        """모든 Jetson 기기 목록 조회 (일반 유저는 MAC 주소 숨김)"""
        # 토큰에서 'level' 숫자를 가져옵니다. (없으면 기본값 1)
        user_level = get_jwt().get("level", 1)

        devices = JetsonDevice.query.all()
        result = []

        for device in devices:
            device_data = device.to_dict()
            # 레벨 1(일반 유저)이면 MAC 주소를 숨깁니다.
            if user_level < 2:
                device_data.pop("mac_address", None)
            result.append(device_data)

        return result, 200

    @devices_ns.expect(device_register_model)
    @devices_ns.doc(security='Bearer', responses={201: '등록 성공', 400: '중복 MAC', 403: '권한 없음'})
    @jwt_required()
    def post(self):
        """새로운 Jetson 기기 등록 (레벨 2 이상 전용)"""
        # 레벨 2(관리자) 미만이면 거부!
        if get_jwt().get("level", 1) < 2:
            return {"error": "접근 거부: 기기 등록은 관리자(레벨 2) 이상만 가능합니다."}, 403

        data = request.get_json()
        mac = data.get('mac_address')
        name = data.get('device_name')

        if JetsonDevice.query.filter_by(mac_address=mac).first():
            return {"error": "이미 등록된 MAC 주소입니다."}, 400

        new_device = JetsonDevice(
            mac_address=mac,
            device_name=name,
            location=data.get('location')
        )

        db.session.add(new_device)
        db.session.commit()

        return {"message": "새 기기가 성공적으로 등록되었습니다.", "device": new_device.to_dict()}, 201


# [상세 조회 & 수정 & 삭제 API] 주소: /<device_id>
@devices_ns.route('/<int:device_id>')
@devices_ns.param('device_id', '조회/수정/삭제할 기기의 고유 ID 번호')
class DeviceDetail(Resource):

    @devices_ns.doc(security='Bearer', responses={200: '성공', 404: '기기 없음'})
    @jwt_required()
    def get(self, device_id):
        """특정 Jetson 기기 상세 조회"""
        user_level = get_jwt().get("level", 1)
        device = JetsonDevice.query.get_or_404(device_id)

        device_data = device.to_dict()
        # 레벨 1(일반 유저)이면 MAC 주소를 숨깁니다.
        if user_level < 2:
            device_data.pop("mac_address", None)

        return device_data, 200

    @devices_ns.expect(device_update_model)
    @devices_ns.doc(security='Bearer', responses={200: '수정 성공', 403: '권한 없음'})
    @jwt_required()
    def put(self, device_id):
        """Jetson 기기 정보 수정 (레벨 2 이상 전용)"""
        # 레벨 2(관리자) 미만이면 거부!
        if get_jwt().get("level", 1) < 2:
            return {"error": "접근 거부: 기기 수정은 관리자(레벨 2) 이상만 가능합니다."}, 403

        device = JetsonDevice.query.get_or_404(device_id)
        data = request.get_json()

        if 'device_name' in data:
            device.device_name = data['device_name']
        if 'location' in data:
            device.location = data['location']

        db.session.commit()
        return {"message": "기기 정보가 수정되었습니다.", "device": device.to_dict()}, 200

    @devices_ns.doc(security='Bearer', responses={200: '삭제 성공', 403: '권한 없음'})
    @jwt_required()
    def delete(self, device_id):
        """더 이상 사용하지 않는 Jetson 기기 삭제 (최고관리자 레벨 3 전용)"""
        # 레벨 3(최고관리자) 미만이면 거부! 오직 레벨 3만 삭제 가능!
        if get_jwt().get("level", 1) < 3:
            return {"error": "접근 거부: 기기 삭제는 최고관리자(레벨 3)만 가능합니다."}, 403

        device = JetsonDevice.query.get_or_404(device_id)
        db.session.delete(device)
        db.session.commit()
        return {"message": f"기기({device.device_name})가 완전히 삭제되었습니다."}, 200