const prisma = require("../src/lib/prisma");

const INTERACTION_TYPES = [
  "VIEW",
  "CLICK",
  "LIKE",
  "SAVE",
  "COMMENT",
];

const TARGET_TYPES = ["POST", "EVENT", "COURSE"];

function random(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomDate(daysBack = 30) {
  const date = new Date();
  date.setDate(date.getDate() - randomInt(0, daysBack));
  return date;
}

async function main() {
  const users = await prisma.user.findMany({ select: { id: true } });
  const posts = await prisma.post.findMany({ select: { id: true } });
  const events = await prisma.event.findMany({ select: { id: true } });
  const courses = await prisma.course.findMany({ select: { id: true } });

  if (!users.length || (!posts.length && !events.length && !courses.length)) {
    console.log("❌ Not enough base data (users + content required)");
    return;
  }

  const targets = {
    POST: posts.map(p => p.id),
    EVENT: events.map(e => e.id),
    COURSE: courses.map(c => c.id),
  };

  const interactions = [];

  for (let i = 0; i < 2000; i++) {
    const targetType = random(TARGET_TYPES);
    const targetList = targets[targetType];

    if (!targetList.length) continue;

    const user = random(users);
    const targetId = random(targetList);
    const type = random(INTERACTION_TYPES);

    interactions.push({
      userId: user.id,
      targetType,
      targetId,
      interactionType: type,
      value: randomInt(1, 3),
      metadata: {
        source: "seed_generator",
        batch: "v1",
      },
      createdAt: randomDate(14),
    });
  }

  await prisma.userInteraction.createMany({
    data: interactions,
    skipDuplicates: true,
  });

  console.log(`🔥 Inserted ${interactions.length} interactions`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());