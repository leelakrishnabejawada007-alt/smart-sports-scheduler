#!/usr/bin/env python3
"""Smart Sports Scheduler - REST API + SQLite database (Python standard library only).

Run:   python3 server.py            (listens on http://0.0.0.0:8000)
Env:   PORT=8000  DB_PATH=scheduler.db

Seed accounts (created on first run):
  admin    admin@sports.edu  / Admin@1234   (change it! see below)
  student  demo@student.edu  / Demo@1234

Make yourself the only admin:
  python server.py set-admin you@college.edu "YourStrongPass1" "Your Name"
  python server.py delete-user admin@sports.edu
First-run seed can also come from env vars ADMIN_EMAIL / ADMIN_PASSWORD.
"""
import hashlib
import hmac
import json
import os
import re
import secrets
import sqlite3
import sys
import time
from contextlib import contextmanager
from datetime import date, datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DB_PATH = os.environ.get("DB_PATH", os.path.join(os.path.dirname(os.path.abspath(__file__)), "scheduler.db"))
SESSION_DAYS = 30
MAX_FAILS, LOCK_SECONDS = 5, 300
FAILS = {}  # email -> (failed attempts, time of first failure)
ACTIVE = ("pending", "approved")

SCHEMA = """
CREATE TABLE IF NOT EXISTS users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  student_id TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS sessions(
  token TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS facilities(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sport TEXT NOT NULL,
  location TEXT NOT NULL,
  description TEXT NOT NULL,
  amenities TEXT NOT NULL,
  slot_hours TEXT NOT NULL,
  price_per_hour INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS bookings(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  facility_id TEXT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  slot_hour INTEGER NOT NULL,
  duration_minutes INTEGER NOT NULL,
  players INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  status TEXT NOT NULL,
  student_name TEXT NOT NULL,
  student_id TEXT NOT NULL,
  created_at TEXT NOT NULL
);
"""


# ----------------------------------------------------------------- helpers
@contextmanager
def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def now_iso():
    return datetime.now().isoformat(timespec="seconds")


def hash_password(password, salt=None):
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt), 200_000)
    return f"{salt}${digest.hex()}"


def verify_password(password, stored):
    salt, _ = stored.split("$")
    return hmac.compare_digest(hash_password(password, salt), stored)


class ApiError(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status
        self.message = message


def facility_json(r):
    return {
        "id": r["id"], "name": r["name"], "sport": r["sport"], "location": r["location"],
        "description": r["description"], "amenities": json.loads(r["amenities"]),
        "slotHours": json.loads(r["slot_hours"]), "pricePerHour": r["price_per_hour"],
    }


def user_json(r):
    return {"id": str(r["id"]), "name": r["name"], "studentId": r["student_id"],
            "email": r["email"], "role": r["role"], "createdAt": r["created_at"]}


def booking_json(r, viewer, show_private):
    own = r["user_id"] == viewer["id"]
    private = own or show_private
    return {
        "id": str(r["id"]), "facilityId": r["facility_id"], "facilityName": r["facility_name"],
        "date": r["date"], "slotHour": r["slot_hour"],
        "studentName": r["student_name"] if private else "Another student",
        "studentId": r["student_id"] if private else "",
        "status": r["status"], "createdAt": r["created_at"],
        "durationMinutes": r["duration_minutes"], "players": r["players"],
        "amount": r["amount"] if private else 0, "isOwn": own,
    }


BOOKING_SELECT = ("SELECT b.*, f.name AS facility_name FROM bookings b "
                  "JOIN facilities f ON f.id = b.facility_id ")


# ----------------------------------------------------------------- seed
def seed(conn):
    if conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]:
        return
    users = [
        ("Admin", "9000001", os.environ.get("ADMIN_EMAIL", "admin@sports.edu"),
         os.environ.get("ADMIN_PASSWORD", "Admin@1234"), "admin"),
        ("Demo Student", "2023001", "demo@student.edu", "Demo@1234", "student"),
        ("Priya Sharma", "2023002", "priya@student.edu", "Demo@1234", "student"),
    ]
    for name, sid, email, pw, role in users:
        conn.execute("INSERT INTO users(name,student_id,email,password_hash,role,created_at) VALUES(?,?,?,?,?,?)",
                     (name, sid, email, hash_password(pw), role, now_iso()))
    facs = [
        ("f1", "Central Basketball Court", "Basketball", "North Campus, Block A",
         "Full-size outdoor court with a rubberised surface, ideal for pickup games and club training.",
         ["Floodlights", "Changing room", "Water station", "Scoreboard"], list(range(8, 22)), 200),
        ("f2", "Riverside Tennis Courts", "Tennis", "East Campus, River Road",
         "Two hard courts beside the river with seating and good evening lighting.",
         ["Floodlights", "Racket rental", "Seating"], list(range(8, 20)), 150),
        ("f3", "Main Football Field", "Football", "South Campus",
         "Natural-grass field marked for 11-a-side, with bleachers for spectators.",
         ["Natural grass", "Floodlights", "Bleachers", "Showers"], list(range(7, 19)), 500),
        ("f4", "Indoor Sports Hall", "Badminton", "Sports Complex, Level 1",
         "Air-conditioned hall with a sprung wooden floor and four badminton courts.",
         ["Air conditioning", "Wooden floor", "Equipment rental", "Lockers"], list(range(7, 21)), 250),
        ("f5", "Beach Volleyball Court", "Volleyball", "West Campus",
         "Sand court with a regulation net, shaded benches and a nearby water point.",
         ["Sand court", "Net provided", "Shade"], list(range(9, 19)), 120),
        ("f6", "Cricket Practice Nets", "Cricket", "South Campus, behind the field",
         "Three net lanes with a bowling machine, for batting and bowling practice.",
         ["Bowling machine", "Pads rental", "Nets"], list(range(8, 18)), 180),
    ]
    for f in facs:
        conn.execute("INSERT INTO facilities VALUES(?,?,?,?,?,?,?,?)",
                     (f[0], f[1], f[2], f[3], f[4], json.dumps(f[5]), json.dumps(f[6]), f[7]))
    priya = conn.execute("SELECT id FROM users WHERE email='priya@student.edu'").fetchone()["id"]
    today = date.today()
    for fid, offset, hour in [("f1", 0, 18), ("f1", 0, 19), ("f3", 0, 16), ("f4", 0, 17), ("f2", 1, 10), ("f4", 1, 9)]:
        conn.execute("INSERT INTO bookings(user_id,facility_id,date,slot_hour,duration_minutes,players,amount,status,"
                     "student_name,student_id,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                     (priya, fid, (today + timedelta(days=offset)).isoformat(), hour, 60, 4, 0, "approved",
                      "Priya Sharma", "2023002", now_iso()))


# ----------------------------------------------------------------- validation
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
ID_RE = re.compile(r"^\d{6,10}$")


def need(body, key, label=None):
    v = body.get(key)
    if v is None or (isinstance(v, str) and not v.strip()):
        raise ApiError(400, f"{label or key} is required")
    return v.strip() if isinstance(v, str) else v


def check_password(pw):
    if len(pw) < 8 or not re.search(r"[A-Za-z]", pw) or not re.search(r"\d", pw):
        raise ApiError(400, "Password must be 8+ characters with a letter and a number")


def parse_facility(body):
    name, sport = need(body, "name", "Name"), need(body, "sport", "Sport")
    location, desc = need(body, "location", "Location"), need(body, "description", "Description")
    amenities = body.get("amenities") or []
    hours = body.get("slotHours") or []
    price = body.get("pricePerHour")
    if (not isinstance(amenities, list) or not isinstance(hours, list) or not hours
            or not all(isinstance(h, int) and 0 <= h <= 23 for h in hours)):
        raise ApiError(400, "Invalid amenities or slot hours")
    if not isinstance(price, int) or price < 0:
        raise ApiError(400, "Price must be a non-negative whole number")
    return name, sport, location, desc, json.dumps([str(a) for a in amenities]), json.dumps(sorted(set(hours))), price


# ----------------------------------------------------------------- handlers
def auth_response(conn, user):
    token = secrets.token_urlsafe(32)
    conn.execute("INSERT INTO sessions(token,user_id,created_at) VALUES(?,?,?)", (token, user["id"], now_iso()))
    return {"token": token, "user": user_json(user)}


def register(conn, body, _u):
    name, sid = need(body, "name", "Name"), need(body, "studentId", "Student ID")
    email, pw = need(body, "email", "Email").lower(), need(body, "password", "Password")
    if len(name) < 2:
        raise ApiError(400, "Enter your full name")
    if not ID_RE.match(sid):
        raise ApiError(400, "Student ID must be 6-10 digits")
    if not EMAIL_RE.match(email):
        raise ApiError(400, "Enter a valid email address")
    check_password(pw)
    if conn.execute("SELECT 1 FROM users WHERE email=?", (email,)).fetchone():
        raise ApiError(409, "An account with this email already exists.")
    if conn.execute("SELECT 1 FROM users WHERE student_id=?", (sid,)).fetchone():
        raise ApiError(409, "This student ID is already registered.")
    cur = conn.execute("INSERT INTO users(name,student_id,email,password_hash,role,created_at) VALUES(?,?,?,?,?,?)",
                       (name, sid, email, hash_password(pw), "student", now_iso()))
    user = conn.execute("SELECT * FROM users WHERE id=?", (cur.lastrowid,)).fetchone()
    return 201, auth_response(conn, user)


def login(conn, body, _u):
    email, pw = need(body, "email", "Email").lower(), need(body, "password", "Password")
    count, first = FAILS.get(email, (0, 0.0))
    if count and time.time() - first > LOCK_SECONDS:
        count = 0
    if count >= MAX_FAILS:
        raise ApiError(429, "Too many failed attempts. Try again in a few minutes.")
    user = conn.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
    if not user or not verify_password(pw, user["password_hash"]):
        FAILS[email] = (count + 1, first if count else time.time())
        raise ApiError(401, "Incorrect email or password.")
    FAILS.pop(email, None)
    return 200, auth_response(conn, user)


def me(conn, body, user):
    return 200, {"user": user_json(user)}


def logout(conn, body, user):
    conn.execute("DELETE FROM sessions WHERE user_id=? AND token=?", (user["id"], user["_token"]))
    return 200, {"ok": True}


def list_facilities(conn, body, user):
    return 200, [facility_json(r) for r in conn.execute("SELECT * FROM facilities ORDER BY rowid")]


def list_bookings(conn, body, user):
    rows = conn.execute(BOOKING_SELECT + "ORDER BY b.created_at").fetchall()
    return 200, [booking_json(r, user, False) for r in rows]


def create_booking(conn, body, user):
    fac = conn.execute("SELECT * FROM facilities WHERE id=?", (need(body, "facilityId"),)).fetchone()
    if not fac:
        raise ApiError(404, "Facility not found")
    try:
        day = date.fromisoformat(str(need(body, "date"))[:10])
    except ValueError:
        raise ApiError(400, "Invalid date")
    hour, minutes = body.get("slotHour"), body.get("durationMinutes", 60)
    players = body.get("players", 1)
    if not isinstance(hour, int) or minutes not in (30, 60, 120):
        raise ApiError(400, "Invalid time slot or duration")
    if not isinstance(players, int) or not 1 <= players <= 30:
        raise ApiError(400, "Players must be between 1 and 30")
    name, sid = need(body, "studentName", "Name"), need(body, "studentId", "Student ID")
    if not ID_RE.match(sid):
        raise ApiError(400, "Student ID must be 6-10 digits")
    hours = -(-minutes // 60)
    allowed = json.loads(fac["slot_hours"])
    if any((hour + i) not in allowed for i in range(hours)):
        raise ApiError(400, "That time is outside the facility's opening slots")
    today = date.today()
    if day < today or day > today + timedelta(days=60):
        raise ApiError(400, "Date must be within the next 60 days")
    if datetime(day.year, day.month, day.day, hour) < datetime.now():
        raise ApiError(409, "That slot has already passed.")
    clash = conn.execute(
        "SELECT 1 FROM bookings WHERE facility_id=? AND date=? AND status IN ('pending','approved') "
        "AND slot_hour < ? AND ? < slot_hour + MAX(1, (duration_minutes + 59) / 60)",
        (fac["id"], day.isoformat(), hour + hours, hour)).fetchone()
    if clash:
        raise ApiError(409, "That slot is no longer available.")
    amount = round(fac["price_per_hour"] * minutes / 60)
    cur = conn.execute(
        "INSERT INTO bookings(user_id,facility_id,date,slot_hour,duration_minutes,players,amount,status,"
        "student_name,student_id,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
        (user["id"], fac["id"], day.isoformat(), hour, minutes, players, amount, "pending", name, sid, now_iso()))
    row = conn.execute(BOOKING_SELECT + "WHERE b.id=?", (cur.lastrowid,)).fetchone()
    return 201, booking_json(row, user, True)


TRANSITIONS_ADMIN = {"pending": {"approved", "rejected", "cancelled"}, "approved": {"rejected", "cancelled"}}
TRANSITIONS_USER = {"pending": {"cancelled"}, "approved": {"cancelled"}}


def update_booking(conn, body, user, bid):
    row = conn.execute(BOOKING_SELECT + "WHERE b.id=?", (bid,)).fetchone()
    if not row:
        raise ApiError(404, "Booking not found")
    is_admin = user["role"] == "admin"
    if not is_admin and row["user_id"] != user["id"]:
        raise ApiError(403, "Not your booking")
    status = need(body, "status")
    table = TRANSITIONS_ADMIN if is_admin else TRANSITIONS_USER
    if status not in table.get(row["status"], set()):
        raise ApiError(400, f"Cannot change a {row['status']} booking to {status}")
    conn.execute("UPDATE bookings SET status=? WHERE id=?", (status, bid))
    row = conn.execute(BOOKING_SELECT + "WHERE b.id=?", (bid,)).fetchone()
    return 200, booking_json(row, user, is_admin)


def require_admin(user):
    if user["role"] != "admin":
        raise ApiError(403, "Admin access required")


def admin_bookings(conn, body, user):
    require_admin(user)
    rows = conn.execute(BOOKING_SELECT + "ORDER BY b.created_at DESC").fetchall()
    return 200, [booking_json(r, user, True) for r in rows]


def admin_users(conn, body, user):
    require_admin(user)
    return 200, [user_json(r) for r in conn.execute("SELECT * FROM users ORDER BY id")]


def admin_create_facility(conn, body, user):
    require_admin(user)
    vals = parse_facility(body)
    fid = "f" + secrets.token_hex(3)
    conn.execute("INSERT INTO facilities VALUES(?,?,?,?,?,?,?,?)", (fid, *vals))
    return 201, facility_json(conn.execute("SELECT * FROM facilities WHERE id=?", (fid,)).fetchone())


def admin_update_facility(conn, body, user, fid):
    require_admin(user)
    if not conn.execute("SELECT 1 FROM facilities WHERE id=?", (fid,)).fetchone():
        raise ApiError(404, "Facility not found")
    vals = parse_facility(body)
    conn.execute("UPDATE facilities SET name=?,sport=?,location=?,description=?,amenities=?,slot_hours=?,"
                 "price_per_hour=? WHERE id=?", (*vals, fid))
    return 200, facility_json(conn.execute("SELECT * FROM facilities WHERE id=?", (fid,)).fetchone())


def admin_delete_facility(conn, body, user, fid):
    require_admin(user)
    cur = conn.execute("DELETE FROM facilities WHERE id=?", (fid,))
    if cur.rowcount == 0:
        raise ApiError(404, "Facility not found")
    return 200, {"ok": True}


# (method, regex, handler, needs_auth)
ROUTES = [
    ("POST", r"/api/auth/register", register, False),
    ("POST", r"/api/auth/login", login, False),
    ("GET", r"/api/auth/me", me, True),
    ("POST", r"/api/auth/logout", logout, True),
    ("GET", r"/api/facilities", list_facilities, False),
    ("GET", r"/api/bookings", list_bookings, True),
    ("POST", r"/api/bookings", create_booking, True),
    ("PATCH", r"/api/bookings/(\d+)", update_booking, True),
    ("GET", r"/api/admin/bookings", admin_bookings, True),
    ("GET", r"/api/admin/users", admin_users, True),
    ("POST", r"/api/admin/facilities", admin_create_facility, True),
    ("PUT", r"/api/admin/facilities/([\w-]+)", admin_update_facility, True),
    ("DELETE", r"/api/admin/facilities/([\w-]+)", admin_delete_facility, True),
]


def current_user(conn, headers):
    auth = headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None
    token = auth[7:]
    row = conn.execute("SELECT u.*, s.created_at AS s_created FROM sessions s JOIN users u ON u.id=s.user_id "
                       "WHERE s.token=?", (token,)).fetchone()
    if not row:
        return None
    if datetime.fromisoformat(row["s_created"]) < datetime.now() - timedelta(days=SESSION_DAYS):
        conn.execute("DELETE FROM sessions WHERE token=?", (token,))
        return None
    user = dict(row)
    user["_token"] = token
    return user


class Handler(BaseHTTPRequestHandler):
    server_version = "SportScheduler/1.0"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self._cors()
        self.end_headers()
        self.wfile.write(data)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def _handle(self, method):
        path = self.path.split("?")[0].rstrip("/") or "/"
        try:
            length = int(self.headers.get("Content-Length") or 0)
            body = {}
            if length:
                try:
                    body = json.loads(self.rfile.read(length))
                except json.JSONDecodeError:
                    raise ApiError(400, "Invalid JSON")
                if not isinstance(body, dict):
                    raise ApiError(400, "JSON object expected")
            for m, pattern, fn, needs_auth in ROUTES:
                match = re.fullmatch(pattern, path)
                if m != method or not match:
                    continue
                with db() as conn:
                    user = current_user(conn, self.headers)
                    if needs_auth and not user:
                        raise ApiError(401, "Please log in")
                    status, payload = fn(conn, body, user, *match.groups())
                return self._send(status, payload)
            raise ApiError(404, "Not found")
        except ApiError as e:
            self._send(e.status, {"error": e.message})
        except Exception as e:  # pragma: no cover
            sys.stderr.write(f"ERROR {e!r}\n")
            self._send(500, {"error": "Server error"})

    def do_GET(self): self._handle("GET")
    def do_POST(self): self._handle("POST")
    def do_PUT(self): self._handle("PUT")
    def do_PATCH(self): self._handle("PATCH")
    def do_DELETE(self): self._handle("DELETE")


def init_db():
    with db() as conn:
        conn.executescript(SCHEMA)
        seed(conn)


def set_admin(email, password, name="Admin"):
    """Create or promote an admin account (run from the terminal, never over HTTP)."""
    email = email.strip().lower()
    if not EMAIL_RE.match(email):
        sys.exit("Invalid email address")
    try:
        check_password(password)
    except ApiError as e:
        sys.exit(e.message)
    with db() as conn:
        row = conn.execute("SELECT id FROM users WHERE email=?", (email,)).fetchone()
        if row:
            conn.execute("UPDATE users SET password_hash=?, role='admin', name=? WHERE id=?",
                         (hash_password(password), name, row["id"]))
            conn.execute("DELETE FROM sessions WHERE user_id=?", (row["id"],))
        else:
            while True:
                sid = "9" + f"{secrets.randbelow(10**6):06d}"
                if not conn.execute("SELECT 1 FROM users WHERE student_id=?", (sid,)).fetchone():
                    break
            conn.execute("INSERT INTO users(name,student_id,email,password_hash,role,created_at) "
                         "VALUES(?,?,?,?,?,?)", (name, sid, email, hash_password(password), "admin", now_iso()))
    print(f"Admin account ready: {email}")


def delete_user(email):
    with db() as conn:
        cur = conn.execute("DELETE FROM users WHERE email=?", (email.strip().lower(),))
    print("Deleted." if cur.rowcount else "No such user.")


if __name__ == "__main__":
    init_db()
    if len(sys.argv) >= 4 and sys.argv[1] == "set-admin":
        set_admin(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else "Admin")
        sys.exit(0)
    if len(sys.argv) == 3 and sys.argv[1] == "delete-user":
        delete_user(sys.argv[2])
        sys.exit(0)
    port = int(os.environ.get("PORT", "8000"))
    print(f"Smart Sports Scheduler API on http://0.0.0.0:{port}/api  (database: {DB_PATH})")
    print("Admin: admin@sports.edu / Admin@1234   Student: demo@student.edu / Demo@1234")
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
