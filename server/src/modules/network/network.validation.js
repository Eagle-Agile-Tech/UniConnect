function validateSendRequest(body) {
  if (!body.receiverId) {
    throw new Error("receiverId is required");
  }
}

function validateRequestId(body) {
  if (!body.requestId) {
    throw new Error("requestId is required");
  }
}

function validateRemove(body) {
  if (!body.targetId) {
    throw new Error("targetId is required");
  }
}

module.exports = {
  validateSendRequest,
  validateRequestId,
  validateRemove,
};
