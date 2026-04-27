/* eslint-disable no-console */

// Minimal seed focused on making the recommendation pipeline usable in dev/Docker.
// Creates:
// - a few users + profiles
// - a handful of posts/events/courses
// - a batch of UserInteraction rows (so dataset export + ML pipeline have data)

require("./config/env");

const prisma = require("./lib/prisma");

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getFlagValue(flag, fallback = null) {
  const idx = process.argv.indexOf(flag);
  if (idx === -1 || idx >= process.argv.length - 1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

function toInt(value, fallback) {
  const n = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

function daysAgo(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d;
}

async function upsertUser({ email, firstName, lastName, role, username, interests }) {
  const user = await prisma.user.upsert({
    where: { email },
    update: {
      firstName,
      lastName,
      role,
      profile: {
        upsert: {
          create: {
            username,
            interests,
            bio: "Seed user for recommendations",
          },
          update: {
            interests,
          },
        },
      },
    },
    create: {
      firstName,
      lastName,
      email,
      role,
      profile: {
        create: {
          username,
          interests,
          bio: "Seed user for recommendations",
        },
      },
    },
    include: { profile: true },
  });
  return user;
}

async function upsertPost({ id, authorId, content, tags = [] }) {
  return prisma.post.upsert({
    where: { id },
    update: {
      content,
      tags,
      moderationStatus: "APPROVED",
      isDeleted: false,
      visibility: "PUBLIC",
    },
    create: {
      id,
      authorId,
      content,
      tags,
      moderationStatus: "APPROVED",
      isDeleted: false,
      visibility: "PUBLIC",
    },
  });
}

async function upsertEvent({ id, authorId, title, description, university }) {
  const starts = new Date();
  starts.setDate(starts.getDate() + (1 + Math.floor(Math.random() * 21)));
  starts.setHours(10 + Math.floor(Math.random() * 8), 0, 0, 0);
  const ends = new Date(starts);
  ends.setHours(ends.getHours() + (1 + Math.floor(Math.random() * 4)));

  return prisma.event.upsert({
    where: { id },
    update: {
      title,
      description,
      starts,
      ends,
      eventDay: starts,
      university,
      location: "Main Campus",
    },
    create: {
      id,
      authorId,
      title,
      description,
      starts,
      ends,
      eventDay: starts,
      university,
      location: "Main Campus",
    },
  });
}

async function upsertCourse({ id, expertId, title, description, videoId, price }) {
  return prisma.course.upsert({
    where: { id },
    update: { title, description, videoId, price, expertId },
    create: { id, title, description, videoId, price, expertId },
  });
}

async function seedInteractions({
  users,
  posts,
  events,
  courses,
  totalInteractions = 50000,
  chunkSize = 2000,
}) {
  const rows = [];
  const maxAgeDays = 14;

  const total = Math.max(0, Number(totalInteractions) || 0);
  if (!total) return { inserted: 0 };

  function pushRow(row) {
    rows.push(row);
    if (rows.length >= chunkSize) {
      return flush();
    }
    return Promise.resolve();
  }

  async function flush() {
    if (!rows.length) return 0;
    const batch = rows.splice(0, rows.length);
    const result = await prisma.userInteraction.createMany({ data: batch });
    return result.count;
  }

  let inserted = 0;
  for (let i = 0; i < total; i += 1) {
    const user = pick(users);
    const bucket = pick(["POST", "POST", "POST", "EVENT", "COURSE"]);
    const createdAt = daysAgo(Math.floor(Math.random() * maxAgeDays));

    if (bucket === "POST") {
      const post = pick(posts);
      const interactionType = pick(["VIEW", "VIEW", "VIEW", "LIKE", "SAVE", "CLICK", "COMMENT", "SHARE"]);
      await pushRow({
        userId: user.id,
        targetType: "POST",
        targetId: post.id,
        interactionType,
        value: interactionType === "CLICK" ? 2 : 1,
        metadata: { seed: true, surface: "feed", version: 2 },
        createdAt,
      });
    } else if (bucket === "EVENT") {
      const event = pick(events);
      const interactionType = pick(["VIEW", "VIEW", "CLICK", "SAVE"]);
      await pushRow({
        userId: user.id,
        targetType: "EVENT",
        targetId: event.id,
        interactionType,
        value: interactionType === "CLICK" ? 2 : 1,
        metadata: { seed: true, surface: "events", version: 2 },
        createdAt,
      });
    } else {
      const course = pick(courses);
      const interactionType = pick(["VIEW", "VIEW", "SAVE", "CLICK"]);
      await pushRow({
        userId: user.id,
        targetType: "COURSE",
        targetId: course.id,
        interactionType,
        value: interactionType === "CLICK" ? 2 : 1,
        metadata: { seed: true, surface: "courses", version: 2 },
        createdAt,
      });
    }
  }

  inserted += await flush();
  return { inserted };
}

async function main() {
  const seedOnlyInteractions = hasFlag("--interactions-only");

  // Defaults tuned for: enough diversity for aggregated training rows + 50k interactions.
  const userCount = Math.max(2, toInt(getFlagValue("--users"), 50));
  const postCount = Math.max(5, toInt(getFlagValue("--posts"), 120));
  const eventCount = Math.max(3, toInt(getFlagValue("--events"), 30));
  const courseCount = Math.max(3, toInt(getFlagValue("--courses"), 30));
  const totalInteractions = Math.max(0, toInt(getFlagValue("--interactions"), 50000));

  const interestPool = ["Web Dev", "AI", "Design", "Entrepreneurship", "Marketing", "Data Science"];

  console.log("Seeding recommendation-friendly data...");

  // Users
  const expert = await upsertUser({
    email: "expert.seed@uniconnect.dev",
    firstName: "Expert",
    lastName: "Seed",
    role: "EXPERT",
    username: "expert_seed",
    interests: ["AI", "Data Science"],
  });

  const students = [];
  for (let i = 1; i <= userCount; i += 1) {
    students.push(
      await upsertUser({
        email: `student${i}.seed@uniconnect.dev`,
        firstName: "Student",
        lastName: `Seed${i}`,
        role: "STUDENT",
        username: `student_seed_${i}`,
        interests: [pick(interestPool), pick(interestPool)].filter((v, idx, arr) => arr.indexOf(v) === idx),
      })
    );
  }

  if (seedOnlyInteractions) {
    const posts = await prisma.post.findMany({ take: 20, orderBy: { createdAt: "desc" } });
    const events = await prisma.event.findMany({ take: 20, orderBy: { createdAt: "desc" } });
    const courses = await prisma.course.findMany({ take: 20, orderBy: { createdAt: "desc" } });
    if (!posts.length || !events.length || !courses.length) {
      throw new Error("Need at least one post, event, and course to seed interactions-only.");
    }
    const seeded = await seedInteractions({
      users: students,
      posts,
      events,
      courses,
      totalInteractions,
    });
    console.log(
      JSON.stringify(
        { users: students.length, interactionsInserted: seeded.inserted, totalInteractions },
        null,
        2,
      )
    );
    return;
  }

  // Content (stable IDs so rerunning seed doesn't spam new content).
  const authorId = students[0].id;

  const posts = [];
  for (let i = 1; i <= postCount; i += 1) {
    const topic = pick(["web", "ai", "design", "career", "campus", "study", "startup"]);
    posts.push(
      await upsertPost({
        id: `seed-post-${String(i).padStart(4, "0")}`,
        authorId,
        content: `Seed post #${i}: discussion about ${topic}.`,
        tags: [topic],
      })
    );
  }

  const events = [];
  for (let i = 1; i <= eventCount; i += 1) {
    events.push(
      await upsertEvent({
        id: `seed-event-${String(i).padStart(4, "0")}`,
        authorId,
        title: `Seed event #${i}`,
        description: "Seed event for recommendations and training.",
        university: "Jimma University",
      })
    );
  }

  const courses = [];
  for (let i = 1; i <= courseCount; i += 1) {
    const topic = pick(["ML", "JavaScript", "UI/UX", "Data", "Marketing"]);
    courses.push(
      await upsertCourse({
        id: `seed-course-${String(i).padStart(4, "0")}`,
        expertId: expert.id,
        title: `Seed course #${i}: ${topic}`,
        description: "Seed course for recommendations and training.",
        videoId: "dQw4w9WgXcQ",
        price: 0,
      })
    );
  }

  const seeded = await seedInteractions({
    users: students,
    posts,
    events,
    courses,
    totalInteractions,
  });

  console.log(
    JSON.stringify(
      {
        users: { expert: expert.id, students: students.length },
        content: { posts: posts.length, events: events.length, courses: courses.length },
        interactionsInserted: seeded.inserted,
        totalInteractionsRequested: totalInteractions,
        hint: "Now rerun: npm run dataset:training:jsonl",
      },
      null,
      2,
    )
  );
}

main()
  .catch((err) => {
    console.error("Seed failed:", err?.message || err);
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      await prisma.$disconnect();
    } catch (_e) {}
  });
