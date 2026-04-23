enum UserRole { STUDENT, EXPERT, INSTITUTION }

enum InstitutionType {UNIVERSITY,
  COMPANY,
  NGO,
  RESEARCH_CENTER,
  TRAINING_CENTER,
  GOVERNMENT,
  OTHER}

// EMAIL_VERIFIED is removed after communication
enum VerificationStatus { PENDING, APPROVED, REJECTED }
enum InstitutionVerificationStatus {
  PENDING,
  UNVERIFIED,
  VERIFIED,
  REJECTED,
}

enum EmailType {institutional, general, invalid}

enum OnboardingStep { account, verifyEmail, academic, profile, completed }
