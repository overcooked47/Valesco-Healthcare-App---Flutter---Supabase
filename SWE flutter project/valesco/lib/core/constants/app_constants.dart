class AppConstants {
  // App Info
  static const String appName = 'VALESCO';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Health, Our Priority';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int phoneNumberLength = 11;
  
  // Health Parameters
  static const double minBloodGlucose = 70.0;
  static const double maxBloodGlucose = 180.0;
  static const double criticalLowGlucose = 54.0;
  static const double criticalHighGlucose = 250.0;
  
  static const int minSystolicBP = 90;
  static const int maxSystolicBP = 140;
  static const int minDiastolicBP = 60;
  static const int maxDiastolicBP = 90;
  
  static const int minHeartRate = 60;
  static const int maxHeartRate = 100;
  
  static const double minTemperature = 36.1;
  static const double maxTemperature = 37.2;
  
  // Location
  static const double hospitalSearchRadius = 10.0; // km
  static const double ambulanceSearchRadius = 15.0; // km
  
  // Notification
  static const int reminderAdvanceMinutes = 5;
  
  // Emergency
  static const int emergencyCancelTimeSeconds = 5;
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
}

class AppStrings {
  // App
  static const String appName = 'VALESCO';
  
  // Authentication
  static const String welcome = 'Welcome to VALESCO';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String dateOfBirth = 'Date of Birth';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String termsAndConditions = 'I agree to the Terms and Conditions';
  static const String verification = 'Verification';
  static const String enterOtp = 'Enter the verification code sent to your email/phone';
  static const String resendOtp = 'Resend Code';
  static const String verify = 'Verify';
  
  // Health Profile
  static const String healthProfile = 'Health Profile';
  static const String personalInfo = 'Personal Information';
  static const String medicalHistory = 'Medical History';
  static const String allergies = 'Allergies';
  static const String emergencyContacts = 'Emergency Contacts';
  static const String age = 'Age';
  static const String gender = 'Gender';
  static const String bloodGroup = 'Blood Group';
  static const String height = 'Height (cm)';
  static const String weight = 'Weight (kg)';
  static const String chronicConditions = 'Chronic Conditions';
  static const String pastSurgeries = 'Past Surgeries';
  static const String currentMedications = 'Current Medications';
  static const String drugAllergies = 'Drug Allergies';
  static const String foodAllergies = 'Food Allergies';
  
  // Medication
  static const String medications = 'Medications';
  static const String addMedication = 'Add Medication';
  static const String medicationName = 'Medication Name';
  static const String dosage = 'Dosage';
  static const String frequency = 'Frequency';
  static const String reminderTime = 'Reminder Time';
  static const String duration = 'Duration';
  static const String notes = 'Notes';
  static const String taken = 'Taken';
  static const String skipped = 'Skipped';
  static const String snoozed = 'Snoozed';
  static const String adherenceRate = 'Adherence Rate';
  static const String refillReminder = 'Refill Reminder';
  static const String pillsRemaining = 'Pills Remaining';
  
  // Health Readings
  static const String healthReadings = 'Health Readings';
  static const String bloodGlucose = 'Blood Glucose';
  static const String bloodPressure = 'Blood Pressure';
  static const String heartRate = 'Heart Rate';
  static const String temperature = 'Temperature';
  static const String oxygenLevel = 'Oxygen Level';
  static const String addReading = 'Add Reading';
  static const String viewHistory = 'View History';
  static const String trends = 'Trends';
  
  // Hospital & Ambulance
  static const String hospitalLocator = 'Hospital Locator';
  static const String ambulanceService = 'Ambulance Service';
  static const String findHospitals = 'Find Hospitals';
  static const String findAmbulance = 'Find Ambulance';
  static const String nearbyHospitals = 'Nearby Hospitals';
  static const String nearbyAmbulances = 'Nearby Ambulances';
  static const String distance = 'Distance';
  static const String services = 'Services';
  static const String callNow = 'Call Now';
  static const String getDirections = 'Get Directions';
  static const String available = 'Available';
  static const String busy = 'Busy';
  
  // Emergency
  static const String emergency = 'Emergency';
  static const String emergencyAlert = 'Emergency Alert';
  static const String sosAlert = 'SOS Alert';
  static const String triggerAlert = 'Press and hold to trigger emergency alert';
  static const String alertSent = 'Emergency alert sent!';
  static const String cancelAlert = 'Cancel Alert';
  static const String helpOnTheWay = 'Help is on the way!';
  
  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String todaysMedications = "Today's Medications";
  static const String healthSummary = 'Health Summary';
  static const String quickActions = 'Quick Actions';
  static const String recentReadings = 'Recent Readings';
  
  // General
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String success = 'Success';
  static const String error = 'Error';
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String logout = 'Logout';
  static const String notifications = 'Notifications';
  static const String language = 'Language';
  static const String help = 'Help';
  static const String about = 'About';
}

class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String logo = '${images}logo.png';
  static const String onboarding1 = '${images}onboarding1.png';
  static const String onboarding2 = '${images}onboarding2.png';
  static const String onboarding3 = '${images}onboarding3.png';
}
