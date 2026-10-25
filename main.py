from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy import create_engine, Column, String, Boolean, Enum as SQLEnum, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel
import uuid
import datetime
import enum

# 1. Настройка БД
DATABASE_URL = "postgresql://user:password@localhost/tutorspace"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. Модели базы данных (SQLAlchemy)
class UserRole(enum.Enum):
    student = "student"
    tutor = "tutor"
    admin = "admin"

class UserDB(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(SQLEnum(UserRole), nullable=False)
    is_blocked = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

Base.metadata.create_all(bind=engine)

# 3. Pydantic схемы
class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str
    role: UserRole

class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: UserRole
    is_blocked: bool

    class Config:
        orm_mode = True

# 4. Инициализация приложения FastAPI
app = FastAPI(title="TutorSpace API")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 5. CRUD операции
@app.post("/api/v1/users/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserDB).filter(UserDB.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = UserDB(
        email=user.email,
        password_hash=user.password + "_hashed", # В реальном проекте использовать bcrypt
        full_name=user.full_name,
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/api/v1/users/{user_id}", response_model=UserResponse)
def read_user(user_id: uuid.UUID, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.put("/api/v1/users/{user_id}", response_model=UserResponse)
def update_user(user_id: uuid.UUID, full_name: str, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.full_name = full_name
    db.commit()
    db.refresh(user)
    return user

@app.delete("/api/v1/users/{user_id}")
def delete_user(user_id: uuid.UUID, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"detail": "User deleted"}