// services/matchScoreService.js
//
// Deterministic skill-overlap match score (0-100) between a user's logged
// skills and a job/internship's required skills. Used by jobController and
// internshipController so the Flutter app can show a real "match %"
// instead of a client-side placeholder heuristic.

const normalize = (str) => String(str || '').trim().toLowerCase();

/**
 * @param {string[]} userSkillNames
 * @param {string[]} requiredSkills
 * @returns {number} 0-100
 */
const computeMatchScore = (userSkillNames = [], requiredSkills = []) => {
  if (!requiredSkills || requiredSkills.length === 0) return 0;
  const userSet = new Set(userSkillNames.map(normalize));
  const matched = requiredSkills.filter((s) => userSet.has(normalize(s)));
  return Math.round((matched.length / requiredSkills.length) * 100);
};

/**
 * Attaches a `matchScore` field to each listing (job/internship) based on
 * the given user's skills. Listings are Mongoose documents or plain
 * objects with a `skillsRequired` array.
 */
const attachMatchScores = (listings, userSkillNames) => {
  return listings.map((listing) => {
    const obj = typeof listing.toObject === 'function' ? listing.toObject() : listing;
    return {
      ...obj,
      matchScore: computeMatchScore(userSkillNames, obj.skillsRequired || []),
    };
  });
};

module.exports = { computeMatchScore, attachMatchScores };
