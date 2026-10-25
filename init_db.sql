-- Создание пользовательских типов (ENUM)
CREATE TYPE user_role AS ENUM ('student', 'tutor', 'admin');
CREATE TYPE lesson_status AS ENUM ('planned', 'completed', 'canceled');
CREATE TYPE homework_status AS ENUM ('pending', 'submitted', 'graded');
CREATE TYPE error_level AS ENUM ('info', 'warning', 'error', 'critical');
-- Таблица пользователей
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Профиль репетитора
CREATE TABLE tutors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    timezone TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Профиль ученика
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone TEXT,
    parent_name TEXT,
    parent_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Предметы
CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Связь репетитор-ученик (обучается)
CREATE TABLE tutor_student (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id UUID NOT NULL REFERENCES tutors(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    rate NUMERIC(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    started_at DATE,
    ended_at DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Занятия
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_student_id UUID NOT NULL REFERENCES tutor_student(id),
    tutor_id UUID NOT NULL REFERENCES tutors(id),
    student_id UUID NOT NULL REFERENCES students(id),
    subject_id INT NOT NULL REFERENCES subjects(id),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status lesson_status DEFAULT 'planned',
    moved_from_id UUID REFERENCES lessons(id),
    cancel_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Заметки к уроку
CREATE TABLE lesson_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID UNIQUE NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Домашнее задание
CREATE TABLE homework (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    description TEXT,
    attachment_url TEXT,
    status homework_status DEFAULT 'pending',
    due_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Журнал ошибок
CREATE TABLE system_error_log (
    id BIGSERIAL PRIMARY KEY,
    level error_level NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    context JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- Аудит действий админа
CREATE TABLE admin_audit_log (
    id BIGSERIAL PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id UUID,
    payload JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);