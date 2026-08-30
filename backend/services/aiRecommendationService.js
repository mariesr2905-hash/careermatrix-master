/**
 * aiRecommendationService.js
 *
 * Modular career-recommendation engine. The controller only ever calls
 * `generateCareerRecommendations()` — it has no knowledge of *how* the
 * recommendations are produced. Today this uses a deterministic,
 * rule-based skill-matching algorithm. To integrate a real external AI
 * API later (OpenAI, a custom ML model, etc.), only this file needs to
 * change: replace the body of `generateCareerRecommendations()` with an
 * API call that returns data in the same shape, and every controller/
 * route in the project keeps working unmodified.
 */

// A small, static knowledge base mapping career roles to the skills they
// typically require. In a production system this might live in its own
// collection, but keeping it here keeps the "engine" self-contained and
// trivially swappable.
const CAREER_SKILL_MAP = [
  {
    role: 'Backend Developer',
    skills: ['Node.js', 'Express', 'MongoDB', 'SQL', 'REST API', 'Java', 'Python', 'Spring Boot'],
  },
  {
    role: 'Frontend Developer',
    skills: ['React', 'JavaScript', 'HTML', 'CSS', 'TypeScript', 'Vue', 'Angular', 'Tailwind CSS'],
  },
  {
    role: 'Full Stack Developer',
    skills: ['React', 'Node.js', 'MongoDB', 'Express', 'JavaScript', 'SQL', 'REST API'],
  },
  {
    role: 'Data Analyst',
    skills: ['SQL', 'Excel', 'Python', 'Power BI', 'Tableau', 'Statistics', 'Data Visualization'],
  },
  {
    role: 'Data Scientist',
    skills: ['Python', 'Machine Learning', 'Statistics', 'Pandas', 'NumPy', 'TensorFlow', 'SQL'],
  },
  {
    role: 'DevOps Engineer',
    skills: ['Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Linux', 'Terraform', 'Jenkins'],
  },
  {
    role: 'Mobile App Developer',
    skills: ['Flutter', 'Dart', 'Kotlin', 'Swift', 'React Native', 'Java', 'Android', 'iOS'],
  },
  {
    role: 'Cloud Engineer',
    skills: ['AWS', 'Azure', 'GCP', 'Terraform', 'Docker', 'Kubernetes', 'Linux'],
  },
  {
    role: 'QA / Test Engineer',
    skills: ['Selenium', 'Manual Testing', 'Automation Testing', 'JIRA', 'API Testing', 'Postman'],
  },
  {
    role: 'UI/UX Designer',
    skills: ['Figma', 'Adobe XD', 'Wireframing', 'User Research', 'Prototyping', 'Sketch'],
  },
  {
    role: 'Product Manager',
    skills: ['Product Strategy', 'Agile', 'Scrum', 'Roadmapping', 'Stakeholder Management', 'JIRA'],
  },
  {
    role: 'Machine Learning Engineer',
    skills: ['Python', 'TensorFlow', 'PyTorch', 'Machine Learning', 'Deep Learning', 'NLP'],
  },
];

const normalize = (str) => String(str || '').trim().toLowerCase();

/**
 * Computes a match score (0-100) between a user's skill set and a role's
 * required skill set, using simple overlap ratio. Interested roles
 * (from the user's stated preferences) get a score boost.
 */
const scoreRole = (roleDef, userSkillsNormalized, interestedRolesNormalized) => {
  const requiredSkills = roleDef.skills;
  const requiredNormalized = requiredSkills.map(normalize);

  const matchedSkills = requiredSkills.filter((skill) =>
    userSkillsNormalized.includes(normalize(skill))
  );
  const missingSkills = requiredSkills.filter(
    (skill) => !userSkillsNormalized.includes(normalize(skill))
  );

  let score = requiredNormalized.length > 0 ? (matchedSkills.length / requiredNormalized.length) * 100 : 0;

  // Boost score if the role matches one of the user's stated interests
  if (interestedRolesNormalized.includes(normalize(roleDef.role))) {
    score = Math.min(100, score + 15);
  }

  return {
    role: roleDef.role,
    matchScore: Math.round(score),
    matchedSkills,
    missingSkills,
    reason:
      matchedSkills.length > 0
        ? `You already have ${matchedSkills.length} of ${requiredSkills.length} key skills for this role: ${matchedSkills.join(', ')}.`
        : `This role requires skills you haven't listed yet, such as ${requiredSkills.slice(0, 3).join(', ')}.`,
  };
};

/**
 * The current (rule-based) recommendation engine implementation.
 * Kept private to this module — swap this out to call an external AI
 * service without touching any controller or route.
 */
const ruleBasedEngine = ({ skills = [], interestedRoles = [] }) => {
  const userSkillsNormalized = skills.map(normalize);
  const interestedRolesNormalized = interestedRoles.map(normalize);

  const scored = CAREER_SKILL_MAP.map((roleDef) =>
    scoreRole(roleDef, userSkillsNormalized, interestedRolesNormalized)
  );

  // Highest match first, top 5 recommendations
  return scored.sort((a, b) => b.matchScore - a.matchScore).slice(0, 5);
};

/**
 * Public entry point used by the controller.
 *
 * @param {Object} input
 * @param {String[]} input.skills - flat array of the user's skill names
 * @param {String[]} [input.interestedRoles] - roles from the user's CareerPreference
 * @param {String} [input.department] - user's academic/professional department
 * @returns {Promise<Array>} array of { role, matchScore, matchedSkills, missingSkills, reason }
 */
const generateCareerRecommendations = async (input) => {
  // NOTE: This function is intentionally async so that swapping in a real
  // external AI API call later (which would be async) requires no change
  // to any caller.
  return ruleBasedEngine(input);
};

/**
 * Static skill -> course catalog. Used to give deterministic, real
 * "recommended courses" without requiring an external course API.
 */
const COURSE_CATALOG = {
  'react': [{ title: 'React - The Complete Guide', provider: 'Udemy', duration: '40h' }],
  'node.js': [{ title: 'Node.js, Express, MongoDB Bootcamp', provider: 'Udemy', duration: '35h' }],
  'python': [{ title: 'Python for Everybody', provider: 'Coursera', duration: '30h' }],
  'sql': [{ title: 'The Complete SQL Bootcamp', provider: 'Udemy', duration: '20h' }],
  'machine learning': [{ title: 'Machine Learning Specialization', provider: 'Coursera (Andrew Ng)', duration: '60h' }],
  'aws': [{ title: 'AWS Certified Cloud Practitioner', provider: 'AWS Training', duration: '25h' }],
  'docker': [{ title: 'Docker & Kubernetes: The Practical Guide', provider: 'Udemy', duration: '22h' }],
  'flutter': [{ title: 'Flutter & Dart - The Complete Guide', provider: 'Udemy', duration: '45h' }],
  'javascript': [{ title: 'The Complete JavaScript Course', provider: 'Udemy', duration: '52h' }],
  'data visualization': [{ title: 'Data Visualization with Tableau', provider: 'Coursera', duration: '18h' }],
  'excel': [{ title: 'Excel Skills for Business', provider: 'Coursera', duration: '15h' }],
  'figma': [{ title: 'Figma UI/UX Design Essentials', provider: 'Udemy', duration: '12h' }],
};

const DEFAULT_COURSES = [
  { title: 'Communication Skills for Professionals', provider: 'Coursera', duration: '10h' },
  { title: 'Introduction to Git & GitHub', provider: 'Udemy', duration: '6h' },
];

/**
 * Deterministic "recommended courses" derived from the user's weakest
 * (Beginner-level) skills, plus a couple of general-purpose defaults.
 * Real, backend-computed data — not hardcoded frontend mock content.
 */
const generateCourseRecommendations = ({ skills = [] }) => {
  const weakSkills = skills.filter((s) => s.proficiencyLevel === 'Beginner').map((s) => s.skillName);
  const seen = new Set();
  const recommendations = [];

  weakSkills.forEach((skillName) => {
    const key = normalize(skillName);
    const matches = COURSE_CATALOG[key];
    if (matches) {
      matches.forEach((course) => {
        const dedupeKey = course.title;
        if (!seen.has(dedupeKey)) {
          seen.add(dedupeKey);
          recommendations.push({ ...course, forSkill: skillName, rating: 4.6 });
        }
      });
    }
  });

  if (recommendations.length === 0) {
    DEFAULT_COURSES.forEach((course) => recommendations.push({ ...course, forSkill: null, rating: 4.5 }));
  }

  return recommendations.slice(0, 6);
};

/**
 * Deterministic resume "analysis" computed from real signals: whether a
 * resume file exists, how many skills the user has logged, and how
 * complete their profile is. No external AI call — real backend logic
 * over the user's actual data, in place of hardcoded frontend mock text.
 */
const generateResumeAnalysis = ({ hasResume, skills = [], profile }) => {
  const strengths = [];
  const improvements = [];
  let score = 30;

  if (hasResume) {
    score += 25;
    strengths.push('Resume is uploaded and available to recruiters.');
  } else {
    improvements.push('Upload a resume so recruiters and the AI matcher can evaluate you.');
  }

  if (skills.length >= 5) {
    score += 20;
    strengths.push(`Strong skill profile with ${skills.length} listed skills.`);
  } else if (skills.length > 0) {
    score += 10;
    improvements.push('Add more skills to your profile — aim for at least 5-8 relevant ones.');
  } else {
    improvements.push('No skills added yet. Add your key skills to improve matching and analysis.');
  }

  const advancedCount = skills.filter((s) => ['Advanced', 'Expert'].includes(s.proficiencyLevel)).length;
  if (advancedCount > 0) {
    score += 10;
    strengths.push(`${advancedCount} skill(s) at Advanced/Expert level stand out to recruiters.`);
  }

  if (profile) {
    if (profile.bio && profile.bio.length > 30) {
      score += 5;
      strengths.push('Profile bio is filled in with a meaningful description.');
    } else {
      improvements.push('Add a short professional bio to your profile.');
    }
    if (profile.linkedin || profile.github) {
      score += 5;
      strengths.push('Portfolio links (LinkedIn/GitHub) are connected.');
    } else {
      improvements.push('Add your LinkedIn/GitHub links to your profile for stronger credibility.');
    }
  } else {
    improvements.push('Complete your profile (bio, links, education) to strengthen your resume score.');
  }

  score = Math.max(0, Math.min(100, Math.round(score)));

  if (strengths.length === 0) strengths.push('Getting started — complete more of your profile to build strengths.');
  if (improvements.length === 0) improvements.push('Great job — keep your skills and resume up to date.');

  return { score, strengths, improvements };
};

module.exports = {
  generateCareerRecommendations,
  generateCourseRecommendations,
  generateResumeAnalysis,
  CAREER_SKILL_MAP, // exported for potential reuse (e.g. an admin endpoint listing supported roles)
};
