const prisma = require("../../../lib/prisma");
const postFeedService = require("./post-feed.service");
const { formatPostDTO } = require("../../../utils/postDTO");

class PostUpdateService {
  async updatePost(postId, userId, data, files = []) {
    const post = await prisma.post.findUnique({
      where: { id: postId },
    });

    if (!post || post.isDeleted) throw new Error("Post not found");

    if (post.authorId !== userId) throw new Error("Unauthorized");

    const updated = await prisma.post.update({
      where: { id: postId },
      data: {
        content: data.content ?? post.content,
        tags: data.tags ?? post.tags,
      },
      include: postFeedService.getPostInclude(userId),
    });

    return formatPostDTO(updated, userId);
  }

  async deletePost(postId, userId) {
    const post = await prisma.post.findUnique({
      where: { id: postId },
    });

    if (!post || post.isDeleted) throw new Error("Post not found");

    if (post.authorId !== userId) throw new Error("Unauthorized");

    await prisma.post.update({
      where: { id: postId },
      data: { isDeleted: true },
    });

    return { message: "Post deleted" };
  }
}

module.exports = new PostUpdateService();
