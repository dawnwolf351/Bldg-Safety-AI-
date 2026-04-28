import threading
from app.users.models import Role, User
from app import create_app, db
from app.devices.tcp_server import start_tcp_server

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # DB 테이블 자동 생성

        # 🌟 [수정된 부분] 3단계 레벨(Level) 권한 시스템으로 세팅!
        if not Role.query.first():
            # 레벨(level) 속성을 반드시 추가해야 합니다.
            super_admin_role = Role(role_name='ROLE_SUPER_ADMIN', description='최고 관리자', level=3)
            admin_role = Role(role_name='ROLE_ADMIN', description='현장 관리자', level=2)
            user_role = Role(role_name='ROLE_USER', description='현장 일반 사용자', level=1)

            db.session.add(super_admin_role)
            db.session.add(admin_role)
            db.session.add(user_role)
            db.session.commit()
            print("✅ [시스템] 3단계 기본 권한(SUPER_ADMIN, ADMIN, USER)이 DB에 성공적으로 세팅되었습니다!")

    # 🌟 TCP 소켓 서버를 백그라운드 쓰레드로 실행!
    # (주의: start_tcp_server 함수가 app 인자를 받도록 구현되어 있어야 합니다)
    tcp_thread = threading.Thread(target=start_tcp_server, args=(app,))
    tcp_thread.daemon = True
    tcp_thread.start()

    # Flask 웹 서버 실행 (얘는 메인 쓰레드에서 돕니다)
    app.run(debug=True, port=8080, use_reloader=False)
    # (주의: use_reloader=False를 안 하면 쓰레드가 2개씩 생겨서 충돌납니다)