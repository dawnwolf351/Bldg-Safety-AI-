import socket
import json
# 🌟 1. Flask 앱과 DB, 모델 불러오기
from app import create_app, db
from app.devices.models import JetsonDevice

# 🌟 2. 소켓 서버 안에서 Flask 기능(DB 접근)을 쓸 수 있게 앱 생성
app = create_app()


def start_server():
    HOST = '0.0.0.0'
    PORT = 5001

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((HOST, PORT))
    server_socket.listen(5)

    print(f"👂 백엔드 소켓 서버가 {PORT}번 포트에서 대기 중...")

    while True:
        client_sock, addr = server_socket.accept()
        print(f"\n🤝 젯슨 기기 연결됨! 접속 IP: {addr[0]}")

        try:
            while True:
                data = client_sock.recv(1024)
                if not data:
                    break

                # 🌟 3. 받은 데이터를 JSON으로 변환해서 MAC 주소 뽑아내기
                try:
                    payload = json.loads(data.decode('utf-8'))
                    mac = payload.get("mac_address")
                except json.JSONDecodeError:
                    print("⚠️ 잘못된 데이터 형식입니다.")
                    continue

                # 🌟 4. DB 장부 열어서 등록된 기기인지 검사하고 IP 업데이트하기!
                with app.app_context():
                    device = JetsonDevice.query.filter_by(mac_address=mac).first()

                    if device:
                        # [핵심 추가] 기기의 현재 접속 IP를 DB 필드에 업데이트!
                        current_ip = addr[0]
                        device.last_known_ip = current_ip

                        # 변경 사항을 DB에 최종 저장
                        db.session.commit()

                        print(f"✅ [승인 및 업데이트 완료] {device.device_name} ({device.location})")
                        print(f"   📍 저장된 IP: {current_ip}")
                        print(f"   📊 상세 데이터: {payload}")

                        client_sock.sendall("서버: 인증 및 IP 업데이트 완료!".encode('utf-8'))
                    else:
                        # DB에 없는 낯선 기기인 경우 (침입자)
                        print(f"🚫 [접근 거부] 미등록 기기 (MAC: {mac}) - 연결을 강제 종료합니다.")
                        client_sock.sendall("서버: 미등록 기기입니다. 관리자에게 등록을 요청하세요.".encode('utf-8'))
                        break  # 루프를 깨고 연결을 끊어버림!

        except ConnectionResetError:
            print("⚠️ 젯슨 기기와의 연결이 비정상적으로 끊어졌습니다.")
        except Exception as e:
            print(f"⚠️ 예상치 못한 오류 발생: {e}")
        finally:
            client_sock.close()


if __name__ == '__main__':
    start_server()