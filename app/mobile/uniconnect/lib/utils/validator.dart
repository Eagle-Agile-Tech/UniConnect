import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/utils/enums.dart';

import '../domain/models/user/user.dart';
import 'helper_functions.dart';

abstract final class UCValidator {
  static String? validateEmptyText(String fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static EmailType validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return EmailType.invalid;
    }

    // 1. Check basic syntax first
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return EmailType.invalid;
    }

    // 2. Now that we know it's a valid format, categorize it
    final domain = value.split('@').last.toLowerCase();

    const academicIndicators = [
      '.edu',
      '.ac.uk', // Be more specific where possible
      '.edu.au',
      '.sch',
    ];

    // Use endsWith or a regex to ensure you're catching the TLD/Subdomain correctly
    bool isAcademic = academicIndicators.any((indicator) =>
    domain.endsWith(indicator) || domain.contains('$indicator.')
    );

    if (isAcademic) {
      return EmailType.institutional;
    }

    return EmailType.general;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 6 characters long.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? validateUsername(String? username){
    if(username == null || username.isEmpty){
      return 'Username is required';
    }
    if (username.length < 4){
      return 'Above 3 characters are allowed';
    }
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if(!regex.hasMatch(username)){
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  static String? validateInterest(List<InterestRecord>? interest) {
    if (interest == null || interest.isEmpty) {
      return null;
    }
    if (interest.toSet().length > 5) {
      return 'You can not select up to 5  interests.';
    }
    return null;
  }

  static String? validateMembers(List<User>? members){
    if (members == null || members.isEmpty) {
      return 'Please select members.';
    }
    if (members.toSet().length < 5) {
      return 'You need at least 5 members to create a community.';
    }
    return null;
  }

  static String? validateUniCode(String? code){
    if (code == null || code.isEmpty) {
      return 'Please provide uni code.';
    }
    return null;
  }

  static String?  validateLink(String? link)  {
    if ( link == null || link.isEmpty) {
      return 'Please provide a link.';
    }
    if(!UCHelperFunctions.isUrl(link)){
      return 'Provide a link';
    }
    return null;
  }
}
