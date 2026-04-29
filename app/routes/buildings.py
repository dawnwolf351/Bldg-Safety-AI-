from flask_restx import Namespace, Resource, fields
from datetime import datetime
from app import db

# 🌟 핵심 수정: Building과 Defect 모델을 합쳐진 하나의 파일에서 동시에 가져옵니다!
from app.models.building import Building, Defect

# ==========================================
# 1. Namespace 및 Swagger Model (DTO) 정의
# ==========================================
building_ns = Namespace('buildings', description='건물 정보 관리 API')
defect_ns = Namespace('defects', description='결함 탐지 이력 관리 API')

building_model = building_ns.model('Building', {
    'building_name': fields.String(required=True, description='건물 이름'),
    'location': fields.String(required=True, description='건물 위치'),
    'completion_date': fields.String(description='완공일자 (YYYY-MM-DD)')
})

defect_model = defect_ns.model('Defect', {
    'building_id': fields.Integer(required=True, description='건물 ID'),
    'device_id': fields.Integer(required=True, description='탐지 기기(Jetson) ID'),
    'defect_type': fields.String(required=True, description='결함 유형 (예: 화재, 균열)'),
    'comment': fields.String(description='상세 설명')
})

# ==========================================
# 🏢 2. 건물(Building) 관련 API 라우트
# ==========================================
@building_ns.route('/')
class BuildingList(Resource):
    def get(self):
        """등록된 모든 건물 목록 조회"""
        buildings = Building.query.all()
        return [b.to_dict() for b in buildings], 200

    @building_ns.expect(building_model)
    def post(self):
        """새로운 건물 정보 등록"""
        data = building_ns.payload
        try:
            comp_date = datetime.strptime(data['completion_date'], '%Y-%m-%d').date() if data.get('completion_date') else None
            new_building = Building(
                building_name=data['building_name'],
                location=data['location'],
                completion_date=comp_date
            )
            db.session.add(new_building)
            db.session.commit()
            return {'message': '건물이 성공적으로 등록되었습니다.'}, 201
        except Exception as e:
            return {'error': str(e)}, 400


# ==========================================
# 🚨 3. 결함(Defect) 관련 API 라우트
# ==========================================
@defect_ns.route('/')
class DefectList(Resource):
    def get(self):
        """전체 결함 탐지 이력 조회"""
        defects = Defect.query.all()
        return [d.to_dict() for d in defects], 200

    @defect_ns.expect(defect_model)
    def post(self):
        """결함 정보 강제 등록 (관리자용/테스트용)"""
        data = defect_ns.payload
        try:
            new_defect = Defect(
                building_id=data['building_id'],
                device_id=data['device_id'],
                defect_type=data['defect_type'],
                comment=data.get('comment')
            )
            db.session.add(new_defect)
            db.session.commit()
            return {'message': '결함 이력이 저장되었습니다.'}, 201
        except Exception as e:
            return {'error': str(e)}, 400