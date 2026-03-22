# Local Setup – CineBook Movie Booking App

Run both the Spring Boot backend and React frontend on your machine. No AWS required.

---

## Prerequisites

- **Java 17+** – [Adoptium](https://adoptium.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
- **Node.js 20+** – [nodejs.org](https://nodejs.org/)
- **Maven 3.9+** – Usually bundled with IDE, or [maven.apache.org](https://maven.apache.org/)

---

## 1. Start the Backend

```bash
cd movie-booking-backend
mvn spring-boot:run
```

*(If you have the Maven wrapper: `./mvnw spring-boot:run`)*

- Backend runs at **http://localhost:8080**
- Uses **H2 in-memory database** (no MySQL needed)
- Seed data is loaded automatically:
  - **Admin:** `admin` / `Admin@1234`
  - **User:** `john` / `User@1234`
  - 4 sample movies with shows and seats

Optional: H2 console at http://localhost:8080/h2-console  
- JDBC URL: `jdbc:h2:mem:moviebookingdb`  
- Username: `sa`  
- Password: *(leave empty)*

---

## 2. Start the Frontend

In a **new terminal**:

```bash
cd movie-booking-frontend
npm install
npm run dev
```

- Frontend runs at **http://localhost:3000**
- Vite proxies `/api` to `http://localhost:8080` – no extra config needed

---

## 3. Test the App

1. Open **http://localhost:3000**
2. **Sign up** or **log in** with `john` / `User@1234`
3. Browse movies, click one, pick a show, select seats (1–5), and complete a booking
4. Log in as **admin** (`admin` / `Admin@1234`) to add movies and shows from `/admin`

---

## Quick Commands

| Task | Command |
|------|---------|
| Backend | `cd movie-booking-backend && mvn spring-boot:run` |
| Frontend | `cd movie-booking-frontend && npm run dev` |
| Backend tests | `cd movie-booking-backend && mvn test` |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Port 8080 in use | Change `server.port` in `application.yml` or stop the other process |
| Port 3000 in use | Change `server.port` in `vite.config.js` |
| CORS errors | Ensure backend is running and CORS allows `http://localhost:3000` |
| "User not found" on login | Restart backend – seed data loads on startup |

---

## What Runs Locally

- **Backend:** Spring Boot + H2 (in-memory)
- **Frontend:** React + Vite dev server
- **S3:** Disabled (`app.aws.enabled: false`) – poster uploads skipped; movies show placeholder
- **AI recommendations:** Work locally (in-JVM logic, no external APIs)
