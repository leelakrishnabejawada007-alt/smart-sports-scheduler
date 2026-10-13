"""Run with:  python3 test_server.py   (starts a throw-away server on port 8765)."""
import json, os, subprocess, sys, tempfile, time, urllib.request, urllib.error
from datetime import date, timedelta

PORT = 8765
BASE = f"http://127.0.0.1:{PORT}/api"


def call(method, path, body=None, token=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json"})
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def main():
    tmp = tempfile.mkdtemp()
    env = dict(os.environ, PORT=str(PORT), DB_PATH=os.path.join(tmp, "t.db"))
    srv = subprocess.Popen([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "server.py")],
                           env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            try:
                call("GET", "/facilities"); break
            except Exception:
                time.sleep(0.1)
        ok = 0

        def check(name, cond):
            nonlocal ok
            print(("PASS " if cond else "FAIL ") + name)
            ok += bool(cond)
            if not cond:
                raise SystemExit(1)

        s, facs = call("GET", "/facilities")
        check("6 seeded facilities", s == 200 and len(facs) == 6 and facs[0]["pricePerHour"] == 200)
        check("bookings need login", call("GET", "/bookings")[0] == 401)
        s, r = call("POST", "/auth/login", {"email": "demo@student.edu", "password": "bad"})
        check("wrong password -> 401", s == 401)
        s, r = call("POST", "/auth/login", {"email": "demo@student.edu", "password": "Demo@1234"})
        check("student login", s == 200 and r["user"]["role"] == "student")
        tok = r["token"]
        s, r = call("GET", "/auth/me", token=tok)
        check("session restore via /auth/me", s == 200 and r["user"]["email"] == "demo@student.edu")

        s, r = call("POST", "/auth/register", {"name": "Ana Lee", "studentId": "2024555",
                    "email": "ana@student.edu", "password": "Passw0rd1"})
        check("register", s == 201 and r["user"]["role"] == "student")
        check("duplicate email -> 409", call("POST", "/auth/register", {"name": "Ana", "studentId": "2024556",
              "email": "ANA@student.edu", "password": "Passw0rd1"})[0] == 409)
        check("weak password -> 400", call("POST", "/auth/register", {"name": "Bo Chen", "studentId": "2024557",
              "email": "bo@student.edu", "password": "short"})[0] == 400)

        day = (date.today() + timedelta(days=3)).isoformat()
        bk = {"facilityId": "f1", "date": day, "slotHour": 12, "durationMinutes": 120, "players": 6,
              "studentName": "Demo Student", "studentId": "2023001"}
        s, b = call("POST", "/bookings", bk, tok)
        check("create booking pending, amount 400", s == 201 and b["status"] == "pending" and b["amount"] == 400)
        s, _ = call("POST", "/bookings", {**bk, "slotHour": 13, "durationMinutes": 60}, tok)
        check("overlapping slot -> 409", s == 409)
        s, _ = call("POST", "/bookings", {**bk, "slotHour": 5}, tok)
        check("outside opening hours -> 400", s == 400)

        s, lst = call("GET", "/bookings", token=tok)
        mine = [x for x in lst if x["isOwn"]]
        others = [x for x in lst if not x["isOwn"]]
        check("my bookings flagged, others anonymised",
              len(mine) == 1 and others and all(o["studentName"] == "Another student" for o in others))

        s, r = call("POST", "/auth/login", {"email": "admin@sports.edu", "password": "Admin@1234"})
        check("admin login", s == 200 and r["user"]["role"] == "admin")
        adm = r["token"]
        check("student blocked from admin API", call("GET", "/admin/bookings", token=tok)[0] == 403)
        s, allb = call("GET", "/admin/bookings", token=adm)
        check("admin sees real names", s == 200 and any(x["studentName"] == "Demo Student" for x in allb))
        s, us = call("GET", "/admin/users", token=adm)
        check("admin lists users", s == 200 and len(us) >= 4)

        s, b2 = call("PATCH", f"/bookings/{b['id']}", {"status": "approved"}, adm)
        check("admin approves", s == 200 and b2["status"] == "approved")
        check("student cannot approve", call("PATCH", f"/bookings/{b['id']}", {"status": "approved"}, tok)[0] == 400)
        s, b3 = call("PATCH", f"/bookings/{b['id']}", {"status": "cancelled"}, tok)
        check("student cancels own booking", s == 200 and b3["status"] == "cancelled")
        s, _ = call("POST", "/bookings", {**bk, "slotHour": 12, "durationMinutes": 60}, tok)
        check("cancelled slot is free again", s == 201)

        s, f = call("POST", "/admin/facilities", {"name": "Squash Court", "sport": "Squash", "location": "Annex",
                    "description": "Glass-back court", "amenities": ["AC"], "slotHours": [9, 10, 11],
                    "pricePerHour": 300}, adm)
        check("admin adds facility", s == 201 and f["pricePerHour"] == 300)
        s, f2 = call("PUT", f"/admin/facilities/{f['id']}", {**f, "pricePerHour": 350}, adm)
        check("admin edits facility", s == 200 and f2["pricePerHour"] == 350)
        check("student cannot add facility", call("POST", "/admin/facilities", f, tok)[0] == 403)
        check("admin deletes facility", call("DELETE", f"/admin/facilities/{f['id']}", token=adm)[0] == 200)

        # --- lockout after repeated failures
        call("POST", "/auth/register", {"name": "Lock Me", "studentId": "2024888",
             "email": "lock@student.edu", "password": "Passw0rd1"})
        codes = [call("POST", "/auth/login", {"email": "lock@student.edu", "password": "wrong"})[0] for _ in range(6)]
        check("account locks after 5 bad passwords", codes[:5] == [401] * 5 and codes[5] == 429)
        check("locked even with the right password",
              call("POST", "/auth/login", {"email": "lock@student.edu", "password": "Passw0rd1"})[0] == 429)

        # --- owner-controlled admin via CLI
        srv_py = os.path.join(os.path.dirname(os.path.abspath(__file__)), "server.py")
        subprocess.run([sys.executable, srv_py, "set-admin", "owner@college.edu", "OwnerPass1", "The Owner"],
                       env=env, check=True, stdout=subprocess.DEVNULL)
        s, r = call("POST", "/auth/login", {"email": "owner@college.edu", "password": "OwnerPass1"})
        check("set-admin creates an admin", s == 200 and r["user"]["role"] == "admin")
        subprocess.run([sys.executable, srv_py, "delete-user", "admin@sports.edu"],
                       env=env, check=True, stdout=subprocess.DEVNULL)
        check("default admin can be removed",
              call("POST", "/auth/login", {"email": "admin@sports.edu", "password": "Admin@1234"})[0] == 401)

        call("POST", "/auth/logout", token=tok)
        check("token invalid after logout", call("GET", "/auth/me", token=tok)[0] == 401)
        print(f"\nAll {ok} checks passed")
    finally:
        srv.terminate()


main()
