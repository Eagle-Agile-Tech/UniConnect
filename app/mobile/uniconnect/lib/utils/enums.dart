enum UserRole { STUDENT, EXPERT, INSTITUTION }

enum InstitutionType {
  UNIVERSITY,
  COMPANY,
  NGO,
  RESEARCH_CENTER,
  TRAINING_CENTER,
  GOVERNMENT,
  OTHER,
}

// EMAIL_VERIFIED is removed after communication
enum VerificationStatus { PENDING, APPROVED, REJECTED }

enum InstitutionVerificationStatus { PENDING, UNVERIFIED, VERIFIED, REJECTED }

enum NetworkStatus { ME, PENDING, CONNECTED }

enum EmailType { institutional, general, invalid }

enum OnboardingStep { account, verifyEmail, academic, profile, completed }

enum ReportTargetType { POST, USER }

enum ReportReason {
  SPAM,
  HARASSMENT,
  HATE_SPEECH,
  INAPPROPRIATE_CONTENT,
  FAKE_ACCOUNT,
  OTHER,
}

extension ReportReasonX on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.SPAM:
        return 'Spam';
      case ReportReason.HARASSMENT:
        return 'Harassment';
      case ReportReason.HATE_SPEECH:
        return 'Hate Speech';
      case ReportReason.INAPPROPRIATE_CONTENT:
        return 'Inappropriate Content';
      case ReportReason.FAKE_ACCOUNT:
        return 'Fake Account';
      case ReportReason.OTHER:
        return 'Other';
    }
  }
}
