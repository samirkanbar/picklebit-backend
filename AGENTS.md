# Picklebit Backend: Team Standards & Context

## 1. Tech Stack & Architecture
- **Language:** Python 3.11 (Standardized for all Lambdas)
- **Framework:** AWS SAM (Infrastructure as Code)
- **Database:** PostgreSQL on RDS via SQLModel (Strict Typing)
- **Agent Framework:** LangGraph (Stateful matching logic)

## 2. Directory Conventions
- `src/models/`: All database schemas. No logic here.
- `src/helpers/`: Shared utilities (db.py, queries.py). 
- `src/agents/`: Specialized agent logic (Matchmaking, Concierge).
- `tests/`: Pytest is mandatory for all new logic.

## 3. The "Picklebit Rating" Logic
- **Skill (40%)**, **Shot Prowess (30%)**, **Mobility (15%)**
- **Competitiveness (10%)**, **Affability (10%)**
- *Note:* Affability is the primary differentiator. Use it in all matchmaking scores.

## 4. Definition of Done
- Code must pass `sam validate`.
- Documentation in `queries.py` must be updated.
- AI must run `pytest` before suggesting a PR.