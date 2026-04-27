const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const registerChatHandlers = require('../modules/chat/chat.socket');
const redisClient = require('../config/redis');
const { createAdapter } = require('@socket.io/redis-adapter');
const { setIO } = require('./io');
const prisma = require('../lib/prisma');

async function joinUserChatRooms(socket) {
  const userId = socket.user?.id;
  if (!userId) return;

  try {
    const chats = await prisma.chatParticipant.findMany({
      where: { userId },
      select: { chatId: true },
    });

    chats.forEach((chat) => {
      socket.join(`chat:${chat.chatId}`);
    });
  } catch (error) {
    console.warn('[socket] failed to auto-join chat rooms:', error.message);
  }
}

function initSocket(httpServer) {
    const io = new Server(httpServer, {
        cors: { origin: ['http://localhost:3000' , 'http://localhost:5173'], credentials: true },
    });
  setIO(io);

  const pubClient = redisClient.duplicate();
  const subClient = redisClient.duplicate();
  Promise.all([pubClient.connect(), subClient.connect()])
    .then(() => {
      io.adapter(createAdapter(pubClient, subClient));
      console.log('Socket.IO Redis adapter connected');
    })
    .catch((err) => {
      console.warn('Socket.IO Redis adapter disabled:', err.message);
    });

  io.use((socket, next) => {
  console.log("HEADERS:", socket.handshake.headers);
  console.log("AUTH:", socket.handshake.auth);

  let token =
    socket.handshake.auth?.token ||
    socket.handshake.headers?.authorization?.split(' ')[1] ||
    socket.handshake.headers?.token;

  console.log("EXTRACTED TOKEN:", token);

  if (!token) {
    console.log(" No token");
    return next(new Error("Unauthorized"));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log("DECODED:", decoded);

    socket.user = {
      id: decoded.id || decoded.sub || decoded.userId,
    };

    next();
  } catch (err) {
    console.log("❌ VERIFY ERROR:", err.message);
    next(new Error("Unauthorized"));
  }
});
    io.on('connection' , async (socket) => {
        socket.join(`user:${socket.user.id}`);
        await joinUserChatRooms(socket);
        registerChatHandlers(io, socket)
});
return io;
}

module.exports = initSocket;
