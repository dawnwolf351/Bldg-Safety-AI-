import threading
from app import create_app
from app.extensions import db, bcrypt
from app.models.role import Role
from app.models.user import User
from app.services.tcp_server import start_tcp_server

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        # 1. 3단계 기본 권한(Role)이 없으면 자동 생성
        if not Role.query.first():
            db.session.add(Role(role_name='ROLE_SUPER_ADMIN', description='최고 관리자', level=1))
            db.session.add(Role(role_name='ROLE_ADMIN', description='현장 관리자', level=2))
            db.session.add(Role(role_name='ROLE_USER', description='일반 사용자', level=3))
            db.session.commit()
            print("[시스템] 3단계 기본 권한이 DB에 생성되었습니다.")

        # 2. 최고관리자 계정이 없으면 자동 생성
        super_admin_email = "boss@capstone.com"
        if not User.query.filter_by(email=super_admin_email).first():
            super_role = Role.query.filter_by(role_name="ROLE_SUPER_ADMIN").first()
            if super_role:
                super_admin = User(
                    email=super_admin_email,
                    password_hash=bcrypt.generate_password_hash("boss1234!").decode('utf-8'),
                    name="최고관리자",
                    role_id=super_role.id
                )
                db.session.add(super_admin)
                db.session.commit()
                print(f"[시스템] 최고관리자 계정({super_admin_email})이 자동 생성되었습니다.")

    # TCP 소켓 서버를 백그라운드 스레드로 실행 (포트 5001)
    tcp_thread = threading.Thread(target=start_tcp_server, args=(app,))
    tcp_thread.daemon = True
    tcp_thread.start()

    # Flask 웹 서버 실행 (메인 스레드, 포트 5000)
    # use_reloader=False: 스레드 중복 생성 방지
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)

