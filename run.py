import threading
from app import create_app
from app.extensions import db
from app.models.role import Role
from app.services.tcp_server import start_tcp_server

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        # 3단계 기본 권한(Role)이 없으면 자동 생성
        if not Role.query.first():
            super_admin_role = Role(role_name='ROLE_SUPER_ADMIN', description='최고 관리자', level=3)
            admin_role = Role(role_name='ROLE_ADMIN', description='현장 관리자', level=2)
            user_role = Role(role_name='ROLE_USER', description='일반 사용자', level=1)

            db.session.add(super_admin_role)
            db.session.add(admin_role)
            db.session.add(user_role)
            db.session.commit()
            print("✅ [시스템] 3단계 기본 권한(SUPER_ADMIN, ADMIN, USER)이 DB에 생성되었습니다!")

    # TCP 소켓 서버를 백그라운드 스레드로 실행 (포트 5001)
    tcp_thread = threading.Thread(target=start_tcp_server, args=(app,))
    tcp_thread.daemon = True
    tcp_thread.start()

    # Flask 웹 서버 실행 (메인 스레드, 포트 5000)
    # use_reloader=False: 스레드 중복 생성 방지
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)

