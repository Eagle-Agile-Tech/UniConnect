const test = require('node:test');
const assert = require('node:assert/strict');

const buildUserResponse = require('../lib/userResponse');

test('buildUserResponse uses expert institution name for university', () => {
  const result = buildUserResponse({
    user: {
      id: 'expert-1',
      role: 'EXPERT',
      firstName: 'Feysel',
      lastName: 'Feysel',
      email: 'fefysleteshome05@gmail.com',
    },
    profile: {
      username: 'bikila',
      university: null,
      universityName: null,
    },
    expertProfile: {
      expertise: 'Computer Science',
      institution: {
        name: 'Jimma University',
      },
    },
  });

  assert.equal(result.university, 'Jimma University');
  assert.deepEqual(result.EXPERT, {
    expertise: 'Computer Science',
    honor: null,
  });
});
