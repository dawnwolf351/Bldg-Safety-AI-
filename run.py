from app import create_app, db

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # 모델이 추가되면 DB에 테이블 자동 생성

    app.run(debug=True, port=8080)