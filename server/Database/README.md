# UniConnect Database

## Overview
UniConnect is a platform for students, experts, and institutions to share content, join communities, and communicate.

This database is managed with **PostgreSQL** and **Prisma ORM**, supporting:

- Users, Experts, Institutions  
- Posts, Comments, Reactions  
- Communities & Memberships  
- Chat & Messages  
- Notifications  
- Media uploads  
- User Education Profiles  
- AI recommendation embeddings  

---

## Tech Stack

- **Database:** PostgreSQL  
- **ORM:** Prisma  
- **Prisma Client:** `@prisma/client`  

---

## Setup

### 1. Install Dependencies

```bash
npm install prisma @prisma/client --save-dev
```

---

### 2. Environment Variables (.env)

Create a `.env` file in your root directory:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/uniconnect"
```

---

### 3. Prisma Schema

Ensure `prisma/schema.prisma` points to your datasource and generator.

Example:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}
```

---

## Prisma Commands

| Command | Purpose |
|----------|----------|
| `npx prisma migrate dev --name <migration_name>` | Create & apply migration (development) |
| `npx prisma migrate deploy` | Apply pending migrations (production) |
| `npx prisma generate` | Generate Prisma client |
| `npx prisma studio` | GUI to explore database |
| `npx prisma db pull` | Pull database schema into Prisma |
| `npx prisma db push` | Push schema changes directly |

> Tip: Use migrations for production. Avoid `db push` in production environments.

---

## Key Models

### User
Core user data including:
- Profile info  
- Interests  
- Role & status  

Relations:
- Posts  
- Comments  
- Reactions  
- Communities  
- Messages  
- Education  
- Expert profile  

---

### Education
Stores user educational information:
- University  
- Department  
- Level  
- Year  

---

### Post & PostComment

Posts support:
- Content  
- Media  
- Visibility  
- AI embeddings  
- Moderation flags  
- Soft delete support  

Comments support:
- Nested replies  
- Moderation  

---

### Reaction
Polymorphic reactions for:
- Posts  
- Comments  
- Messages  
- Users  

---

### Community & CommunityMember
- Community profiles  
- Member roles  
- Media support  

---

### Chat & Message
- Direct chats  
- Group chats  
- Optional media attachments  

---

### Notification
Polymorphic notifications with:
- Optional actor  
- Optional reference entity  

---

### Media
Supports:
- Posts  
- Messages  
- Communities  
- Generic references (hybrid approach)  

---

## Best Practices for Production

- Always use migrations for schema changes  
- Index frequently queried fields (`userId`, `authorId`)  
- Use soft deletes (`isDeleted`) for moderation  
- Optimize embeddings (PostgreSQL vector or JSON arrays)  
- Encrypt sensitive data (passwords, tokens)  
- Backup your database before applying migrations  

---

## Migration & Deployment

### Initial Migration (Development)

```bash
npx prisma migrate dev --name init
```

---

### Add Changes

```bash
npx prisma migrate dev --name add_user_profile
```

---

### Deploy to Production

```bash
npx prisma migrate deploy
```

---

### Generate Prisma Client

```bash
npx prisma generate
```

---

### Open Prisma Studio

```bash
npx prisma studio
```

---

## License

Internal project – UniConnect
