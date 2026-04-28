import socket
import threading
import json
from datetime import datetime
from app.devices.models import JetsonDevice
from app import db


# 1. Jetson에서 전화가 오면 전화를 받는 함수
def handle_client(client_socket, addr, app):
    print(f"\n🤝 [TCP 서버] 새로운 기기 연결됨: IP={addr[0]}")

    # 핵심: 백그라운드 쓰레드에서도 DB를 쓰려면 app_context()가 꼭 필요합니다!
    with app.app_context():
        try:
            # 🌟 [수정 1] 한 번만 받고 끊는 게 아니라, 기기가 끊기 전까지 계속 듣도록 while 루프 추가!
            while True:
                data = client_socket.recv(1024).decode('utf-8')

                # 데이터가 비어있으면 기기 쪽에서 전화를 끊은 것임
                if not data:
                    print(f"⚠️ [TCP 서버] 기기({addr[0]})가 통신을 종료했습니다.")
                    break

                info = json.loads(data)

                # 🌟 [수정 2] test_client.py에서 보내는 이름인 'mac_address'로 수정!
                mac = info.get('mac_address')

                if mac:
                    # DB에서 MAC 주소로 기기 찾기
                    device = JetsonDevice.query.filter_by(mac_address=mac).first()

                    if not device:
                        # 앱(DB)에 미리 등록되지 않은 낯선 기기면? 가차 없이 연결 끊기!
                        print(f"🚨 보안 경고: 미등록 기기({mac})의 불법 접근 시도! 연결을 차단합니다.")
                        client_socket.send("UNAUTHORIZED: 앱에서 먼저 기기를 등록해주세요.".encode('utf-8'))
                        break  # 무한 루프를 깨고 나가서 소켓을 닫아버림

                    # IP 주소 훔쳐오기 및 생존 신고 업데이트!
                    device.last_known_ip = addr[0]
                    # device.is_online = True  (만약 모델에 이 필드가 있다면 살리세요)
                    # device.last_connected_at = datetime.utcnow() (모델에 있다면 살리세요)

                    db.session.commit()
                    print(f"✅ [TCP 서버] 정상 수신: MAC={mac}, 데이터={info}")

                    # Jetson에게 "잘 받았어!" 라고 응답 보내기
                    client_socket.send('{"status": "ok"}'.encode('utf-8'))

        except ConnectionResetError:
            print(f"⚠️ [TCP 서버] 기기({addr[0]})와의 연결이 비정상적으로 끊어졌습니다.")
        except Exception as e:
            print(f"⚠️ [TCP 서버] 에러 발생: {e}")
        finally:
            # 🌟 무한 루프가 다 끝나거나 에러가 났을 때만 전화를 끊습니다!
            client_socket.close()
            print(f"🔌 [TCP 서버] 소켓 통신이 안전하게 닫혔습니다: {addr[0]}")


# 2. 전화 교환국(서버)을 무한히 돌리는 함수
def start_tcp_server(app, host='0.0.0.0', port=5001):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # 포트 충돌 방지
    server.bind((host, port))
    server.listen(5)
    print(f"[*] TCP 소켓 서버가 {port} 포트에서 기기들을 기다립니다...")

    while True:
        # 기기가 접속할 때마다 새로운 쓰레드(직원)를 배정해서 응대함
        client, addr = server.accept()
        thread = threading.Thread(target=handle_client, args=(client, addr, app))
        thread.daemon = True  # 메인 서버가 꺼지면 같이 꺼지도록 설정
        thread.start()