import os
import logging
import datetime
from apscheduler.schedulers.background import BackgroundScheduler
from sqlalchemy import text
from flask import jsonify, Flask
from flask_sqlalchemy import SQLAlchemy
from config import db_username, db_password, db_host, db_port, db_name
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey


port_number = int(os.environ.get("APP_PORT", 5153))
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = f"postgresql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}"
app.logger.setLevel(logging.DEBUG)

db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    joined_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    def __repr__(self):
        return "<User %r>" % self.id

class Token(db.Model):
    __tablename__ = "tokens"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(String(6), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    used_at = Column(DateTime)

    def __repr__(self):
        return "<Token %r>" % self.id

with app.app_context():
    db.create_all()

@app.route("/health_check")
def health_check():
    return "ok"


@app.route("/readiness_check")
def readiness_check():
    try:
        count = db.session.query(Token).count()
    except Exception as e:
        app.logger.error(e)
        return "failed", 500
    else:
        return "ok"


def get_daily_visits():
    with app.app_context():
        result = db.session.execute(text("""
        SELECT Date(created_at) AS date,
            Count(*)         AS visits
        FROM   tokens
        WHERE  used_at IS NOT NULL
        GROUP  BY Date(created_at)
        """))

        response = {}
        for row in result:
            response[str(row[0])] = row[1]

        app.logger.info(response)

    return response


@app.route("/api/reports/daily_usage", methods=["GET"])
def daily_visits():
    return jsonify(get_daily_visits())


@app.route("/api/reports/user_visits", methods=["GET"])
def all_user_visits():
    result = db.session.execute(text("""
    SELECT t.user_id,
        t.visits,
        users.joined_at
    FROM   (SELECT tokens.user_id,
                Count(*) AS visits
            FROM   tokens
            GROUP  BY user_id) AS t
        LEFT JOIN users
                ON t.user_id = users.id;
    """))

    response = {}
    for row in result:
        response[row[0]] = {
            "visits": row[1],
            "joined_at": str(row[2])
        }
    
    return jsonify(response)


scheduler = BackgroundScheduler()
job = scheduler.add_job(get_daily_visits, 'interval', seconds=30)
scheduler.start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port_number)