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

1. **Install Dependencies**
```bash
npm install prisma @prisma/client --save-dev

Environment Variables (.env)

DATABASE_URL="postgresql://user:password@localhost:5432/uniconnect"

Prisma Schema
Ensure prisma/schema.prisma points to your datasource and generator.

Prisma Commands
Command	Use
npx prisma migrate dev --name <migration_name>	Create & apply migration (dev)
npx prisma migrate deploy	Apply pending migrations (production)
npx prisma generate	Generate Prisma client
npx prisma studio	GUI to explore DB
npx prisma db pull	Pull DB schema into Prisma
npx prisma db push	Push schema changes directly

Tip: Use migrations for production; avoid db push.

Key Models
User

Core user data including profile info, interests, role, and status.
Relations: posts, comments, reactions, communities, messages, education, expert profile.

Education

User educational info (university, department, level, year).

Post & PostComment

Posts support content, media, visibility, embeddings (for AI recommendations), moderation, and soft delete.
Comments support nested replies and moderation.

Reaction

Polymorphic reactions for posts, comments, messages, or users.

Community & CommunityMember

Communities with members, roles, and media.

Chat & Message

Direct or group chats with optional media attachments.

Notification

Polymorphic notifications with optional actor and reference.

Media

Supports posts, messages, communities, or generic references (hybrid approach).

Best Practices for Production

Always use migrations for schema changes.

Index frequently queried fields (e.g., userId, authorId).

Use soft deletes (isDeleted) for content moderation.

Keep embeddings optimized for AI features (PostgreSQL vector or JSON arrays).

Encrypt sensitive data (passwords, tokens).

Backup your database regularly before applying migrations.

Migration & Deployment

Initial Migration (Dev)

npx prisma migrate dev --name init

Add Changes

npx prisma migrate dev --name add_user_profile

Deploy to Production

npx prisma migrate deploy

Generate Prisma Client

npx prisma generate

Open Prisma Studio

npx prisma studio