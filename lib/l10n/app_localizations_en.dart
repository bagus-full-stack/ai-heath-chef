// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Health Chef';

  @override
  String get bmiCategoryUnderweight => 'Underweight';

  @override
  String get bmiCategoryNormal => 'Normal weight';

  @override
  String get bmiCategoryOverweight => 'Overweight';

  @override
  String get bmiCategoryObese => 'Obesity';

  @override
  String get aboutAppBarTitle => 'About';

  @override
  String get aboutAppName => 'AI Health Chef';

  @override
  String get aboutContactLinkTitle => 'Contact support';

  @override
  String aboutCopyright(int year) {
    return '© $year AI Health Chef';
  }

  @override
  String get aboutDescription =>
      'AI Health Chef helps you track your meals and nutritional goals: scan your plate for an automatic estimate of calories and macros, chat with an AI coach, get personalized meal ideas, and reminders so you never forget.';

  @override
  String get aboutHelpCenterLinkTitle => 'Help Center';

  @override
  String get aboutMailtoSubject => 'AI Health Chef Contact';

  @override
  String aboutNoMailAppSnackbar(String supportEmail) {
    return 'No mail app configured. Write to us at $supportEmail.';
  }

  @override
  String get aboutTermsLinkTitle => 'Terms of Use';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get aboutVersionLoading => '…';

  @override
  String get accountAgeLabel => 'Age';

  @override
  String get accountAgeSuffix => 'yrs';

  @override
  String accountBmiLabel(String label) {
    return 'BMI: $label';
  }

  @override
  String get accountBmiPlaceholder =>
      'Enter your weight and height to see your BMI.';

  @override
  String accountBmiRangeLabel(String label, String range) {
    return '$label range: $range';
  }

  @override
  String get accountChooseFromGallery => 'Choose from gallery';

  @override
  String get accountCurrentWeightLabel => 'Current weight';

  @override
  String get accountErrorInvalidAge => 'Enter a valid age.';

  @override
  String get accountErrorInvalidCurrentWeight => 'Enter your current weight.';

  @override
  String get accountErrorInvalidHeight => 'Enter your height in cm.';

  @override
  String get accountErrorInvalidTargetWeight => 'Enter a valid target weight.';

  @override
  String get accountErrorNameEmpty => 'Your name can\'t be empty.';

  @override
  String get accountFullNameLabel => 'Full name';

  @override
  String get accountGoalGainMuscle => 'Build muscle';

  @override
  String get accountGoalLoseWeight => 'Lose weight';

  @override
  String get accountGoalMaintain => 'Maintain';

  @override
  String get accountHeightLabel => 'Height';

  @override
  String get accountHeightSuffix => 'cm';

  @override
  String accountLoadError(String error) {
    return 'Couldn\'t load your profile: $error';
  }

  @override
  String get accountMainGoalLabel => 'Main goal';

  @override
  String get accountSaveButton => 'Save';

  @override
  String accountSaveError(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get accountSexFemale => 'Female';

  @override
  String get accountSexLabel => 'Sex';

  @override
  String get accountSexMale => 'Male';

  @override
  String get accountSexOther => 'Other';

  @override
  String get accountTakePhoto => 'Take a photo';

  @override
  String get accountTargetWeightLabel => 'Target weight';

  @override
  String get accountTitle => 'MY ACCOUNT';

  @override
  String get accountUpdateSuccess => 'Profile updated.';

  @override
  String get accountWeightSuffix => 'kg';

  @override
  String get barcodeScannerHintCaption => 'Frame the product\'s barcode';

  @override
  String get barcodeScannerTitleCaption => 'SCAN A PRODUCT';

  @override
  String get cameraCaptureAiAnalysisCaption => 'AI NUTRITION ANALYSIS';

  @override
  String get cameraCaptureBackButton => 'Back';

  @override
  String get cameraCaptureCameraErrorFallback => 'Couldn\'t open the camera.';

  @override
  String cameraCaptureCaptureFailedMessage(String error) {
    return 'Capture failed: $error';
  }

  @override
  String get cameraCaptureChooseGalleryPhotoButton =>
      'Choose a photo from the gallery';

  @override
  String get cameraCaptureFrameMealHint => 'Frame your dish in the center';

  @override
  String get cameraCaptureFrameProductHint => 'Frame the product\'s label';

  @override
  String get cameraCaptureGalleryButton => 'GALLERY';

  @override
  String cameraCaptureGalleryOpenError(String error) {
    return 'Couldn\'t open the gallery: $error';
  }

  @override
  String get cameraCaptureHelpBody =>
      'Center your plate in the circle, hold your device steady, then tap the shutter. Our AI automatically analyzes the food and its nutritional values.';

  @override
  String get cameraCaptureHelpDismiss => 'Got it';

  @override
  String get cameraCaptureHelpTitle => 'How does it work?';

  @override
  String get cameraCaptureModeMeal => 'Meal';

  @override
  String get cameraCaptureModeProduct => 'Product';

  @override
  String get cameraCaptureModeScanner => 'Scanner';

  @override
  String get cameraCaptureNoCameraMessage =>
      'No camera available on this device.';

  @override
  String cameraCaptureOpenCameraError(String error) {
    return 'Couldn\'t open the camera: $error';
  }

  @override
  String get cameraCaptureRetryButton => 'Retry';

  @override
  String get checkoutAppBarTitle => 'Complete your order';

  @override
  String checkoutConfirmButton(String price, String period) {
    return 'Confirm • $price $period';
  }

  @override
  String get checkoutDefaultPlanTitle => 'PRO subscription';

  @override
  String get checkoutDemoModeNotice =>
      'Demo mode: this purchase is simulated, no payment or App Store / Google Play account is involved.';

  @override
  String get checkoutOrderSummaryBrand => 'AI Health Chef PRO';

  @override
  String get checkoutOrderSummaryDemoNotice =>
      'Demo mode — the purchase will be simulated, no real payment';

  @override
  String get checkoutPaymentMethodLabel => 'PAYMENT METHOD';

  @override
  String get checkoutPendingConfirmation =>
      'Purchase made, waiting for confirmation.';

  @override
  String get checkoutPlanLabel => 'Plan';

  @override
  String checkoutPurchaseError(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get checkoutRenewalDisclaimer =>
      'Your subscription renews automatically unless cancelled at least 24h before the end of the period, from your App Store or Google Play account settings.';

  @override
  String get checkoutRenewalLabel => 'Renewal';

  @override
  String get checkoutRenewalValue => 'Automatic, cancel anytime';

  @override
  String get checkoutSecurePaymentNotice =>
      'Payment is securely handled by the App Store / Google Play. No banking information is requested in the app.';

  @override
  String get checkoutSuccessDemo =>
      'Simulated purchase (demo mode)\nPRO access unlocked!';

  @override
  String get checkoutSuccessReal =>
      'Subscription activated!\nWelcome to AI Health Chef PRO.';

  @override
  String get checkoutSummaryLabel => 'SUMMARY';

  @override
  String get checkoutTotalLabel => 'Total';

  @override
  String coachAdjustMealPresetMessage(String mealTitle) {
    return 'Adjust this meal for my goal: $mealTitle';
  }

  @override
  String get coachCancelButton => 'Cancel';

  @override
  String get coachCarbsLabel => 'CARBS';

  @override
  String get coachDailyObjectiveTitle => 'DAILY GOAL';

  @override
  String get coachFatLabel => 'FAT';

  @override
  String get coachGoalMaintainLabel => 'Maintenance';

  @override
  String get coachHeaderTitle => 'NUTRITION COACH';

  @override
  String get coachInputHint => 'Type your question...';

  @override
  String get coachKcalUnitLabel => ' kcal';

  @override
  String get coachMealSuggestionsEmptyText =>
      'No meal ideas available right now.';

  @override
  String get coachMealSuggestionsErrorText =>
      'We couldn\'t generate meal ideas right now.';

  @override
  String coachNeedValueGrams(int current, int target) {
    return '$current/${target}g';
  }

  @override
  String get coachNeedsTitle => 'YOUR NEEDS';

  @override
  String get coachNextMealIdeasTitle => 'Next Meal Ideas';

  @override
  String get coachPersonalizationAppBarTitle => 'AI Coach';

  @override
  String get coachPersonalizationIntro =>
      'Choose the tone your AI Coach uses in its replies.';

  @override
  String get coachPersonalizationToneBienveillantDescription =>
      'Gentle, reassuring, no judgment about your slip-ups.';

  @override
  String get coachPersonalizationToneBienveillantLabel => 'Caring & calm';

  @override
  String get coachPersonalizationToneDirectDescription =>
      'Straight to the point, actionable advice with no detours.';

  @override
  String get coachPersonalizationToneDirectLabel => 'Direct & concise';

  @override
  String get coachPersonalizationToneHumoristiqueDescription =>
      'Light and funny, while still being useful.';

  @override
  String get coachPersonalizationToneHumoristiqueLabel => 'Humorous';

  @override
  String get coachPersonalizationToneMotivantDescription =>
      'Encouraging, upbeat, pushes you to keep going.';

  @override
  String get coachPersonalizationToneMotivantLabel => 'Motivating & energetic';

  @override
  String get coachPromptFatLossLabel => 'Fat loss';

  @override
  String get coachPromptFatLossMessage =>
      'How can I optimize my fat loss today?';

  @override
  String get coachPromptIdeasLabel => 'Meal ideas';

  @override
  String get coachPromptIdeasMessage => 'Give me a high-protein meal idea.';

  @override
  String get coachPromptPostWorkoutLabel => 'Post-workout';

  @override
  String get coachPromptPostWorkoutMessage =>
      'What should I eat after my workout to recover?';

  @override
  String get coachProteinLabel => 'PROTEIN';

  @override
  String get coachRealtimeBannerLabel => 'REAL-TIME ANALYSIS';

  @override
  String coachRemainingKcalText(int remainingKcal, String goalLabel) {
    return 'You have $remainingKcal kcal left to reach your $goalLabel goal.';
  }

  @override
  String get coachResetButton => 'Reset';

  @override
  String get coachResetDialogContent =>
      'Your entire chat history with the coach will be deleted.';

  @override
  String get coachResetDialogTitle => 'Reset the conversation?';

  @override
  String get coachResetTooltip => 'Reset the conversation';

  @override
  String get coachRetryButton => 'Retry';

  @override
  String get coachSeeAllButton => 'See all';

  @override
  String get coachSheetSubtitle => 'Ask a question about your meals';

  @override
  String get coachTipFatLossText =>
      'To optimize your fat loss, go for lean protein sources like chicken breast or tofu for your next meal.';

  @override
  String get coachTipTitle => 'AI Chef\'s Tip';

  @override
  String get coachTitle => 'AI Coach';

  @override
  String get comingSoonDefaultMessage => 'This feature is coming soon.';

  @override
  String get comingSoonDefaultTitle => 'Coming soon';

  @override
  String dashboardBmiLabel(String label) {
    return 'BMI: $label';
  }

  @override
  String dashboardBmiRangeLabel(String label, String range) {
    return '$label range: $range';
  }

  @override
  String dashboardCalorieGoalLabel(int kcal) {
    return ' Goal: $kcal';
  }

  @override
  String get dashboardCarbsLabel => 'CARBS';

  @override
  String get dashboardEmptyMealsMessage =>
      'No meals logged today yet. Scan your first plate!';

  @override
  String get dashboardFatLabel => 'FAT';

  @override
  String get dashboardKcalRemainingLabel => 'KCAL LEFT';

  @override
  String dashboardMealCaloriesLabel(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get dashboardMealJournalTitle => 'Meal log';

  @override
  String dashboardMealsLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get dashboardProteinLabel => 'PROTEIN';

  @override
  String get dashboardTodayTitle => 'Today';

  @override
  String get dietaryPreferencesAllergiesDescription =>
      'These will be avoided in the meal ideas suggested by the AI. This doesn\'t replace your own vigilance in case of a severe allergy.';

  @override
  String get dietaryPreferencesAllergiesSectionTitle =>
      'ALLERGIES & INTOLERANCES';

  @override
  String get dietaryPreferencesDietHalal => 'Halal';

  @override
  String get dietaryPreferencesDietKosher => 'Kosher';

  @override
  String get dietaryPreferencesDietNone => 'No restriction';

  @override
  String get dietaryPreferencesDietPescetarian => 'Pescatarian';

  @override
  String get dietaryPreferencesDietSectionTitle => 'DIET';

  @override
  String get dietaryPreferencesDietVegan => 'Vegan';

  @override
  String get dietaryPreferencesDietVegetarian => 'Vegetarian';

  @override
  String get dietaryPreferencesOtherAllergyHint => 'Other allergy...';

  @override
  String get dietaryPreferencesSaveButton => 'Save';

  @override
  String get dietaryPreferencesSavedSnackbar => 'Preferences saved!';

  @override
  String get dietaryPreferencesTitle => 'Dietary preferences';

  @override
  String get forgotPasswordBackToLogin => 'Back to login';

  @override
  String get forgotPasswordEmailHint => 'example@email.com';

  @override
  String get forgotPasswordEmailLabel => 'Email address';

  @override
  String get forgotPasswordErrorEmailRequired =>
      'Please enter your email address.';

  @override
  String get forgotPasswordSubmitButton => 'Send link';

  @override
  String get forgotPasswordSubtitle =>
      'Don\'t worry, it happens.\nEnter your email to receive a\nreset link.';

  @override
  String get forgotPasswordSuccessMessage =>
      'Reset link sent! Check your email.';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get helpCenterAccountQ1Answer =>
      'Go to Profile > Account to edit your information, or Profile > My goals to adjust your goal (weight loss, muscle gain, maintenance) and your physical data.';

  @override
  String get helpCenterAccountQ1Question =>
      'How do I edit my profile or my goals?';

  @override
  String get helpCenterAccountQ2Answer =>
      'Your subscription is managed directly by the App Store or the Google Play Store (depending on your device), not by the app itself. Go to the subscription settings of your Apple/Google account to change or cancel it.';

  @override
  String get helpCenterAccountQ2Question =>
      'How do I manage or cancel my PRO subscription?';

  @override
  String helpCenterAccountQ3Answer(String supportEmail) {
    return 'Write to us at $supportEmail from the email address associated with your account, and we\'ll take care of deleting your data.';
  }

  @override
  String get helpCenterAccountQ3Question => 'How do I delete my account?';

  @override
  String get helpCenterAppBarTitle => 'Help Center';

  @override
  String get helpCenterCoachQ1Answer =>
      'From the Coach tab, tap the \"AI Coach\" button at the bottom of the screen to open the chat. You can ask it questions about your nutrition, your goals, or ask it for advice.';

  @override
  String get helpCenterCoachQ1Question => 'How do I talk to the AI Coach?';

  @override
  String get helpCenterCoachQ2Answer =>
      'The Coach tab offers meal ideas generated based on your profile and goal. Tap \"See all\" for the full list, then tap the refresh icon (or pull down on the screen) to generate new ones.';

  @override
  String get helpCenterCoachQ2Question => 'How do I get new meal ideas?';

  @override
  String get helpCenterContactButtonLabel => 'Contact support';

  @override
  String get helpCenterMailtoSubject => 'AI Health Chef Question';

  @override
  String get helpCenterMealsQ1Answer =>
      'From the Dashboard, tap the camera button at the bottom right to take a photo of your plate. The AI identifies the ingredients and estimates the calories and macros; you can adjust the quantities, add, or remove an ingredient before confirming.';

  @override
  String get helpCenterMealsQ1Question => 'How do I log a meal?';

  @override
  String get helpCenterMealsQ2Answer =>
      'The analysis is done by an AI model (Google Gemini) based on the photo: it\'s an estimate, not an exact measurement. Adjust the quantities if needed, or manually add an ingredient with its exact values via \"Add an ingredient\".';

  @override
  String get helpCenterMealsQ2Question => 'Is the calorie estimate accurate?';

  @override
  String get helpCenterMealsQ3Answer =>
      'The Dashboard shows today\'s \"Meal log\", with the calorie and macro totals. It resets every day at midnight.';

  @override
  String get helpCenterMealsQ3Question =>
      'Where can I see the meals I\'ve logged today?';

  @override
  String helpCenterNoMailAppSnackbar(String supportEmail) {
    return 'No mail app configured. Write to us at $supportEmail.';
  }

  @override
  String get helpCenterNotFoundSubtitle =>
      'Write to us, we\'ll get back to you directly.';

  @override
  String get helpCenterNotFoundTitle => 'Couldn\'t find your answer?';

  @override
  String get helpCenterRemindersQ1Answer =>
      'Go to Profile > Notifications. Turn on the switch for the meal you want (breakfast, lunch, dinner) and choose the reminder time by tapping the time shown.';

  @override
  String get helpCenterRemindersQ1Question =>
      'How do I turn on meal reminders?';

  @override
  String get helpCenterRemindersQ2Answer =>
      'Check that notifications are allowed for the app in your phone\'s settings. On some Android phones, you also need to disable battery optimization for the app so reminders go off at the scheduled time.';

  @override
  String get helpCenterRemindersQ2Question =>
      'I haven\'t received any notifications, what should I do?';

  @override
  String get helpCenterSectionAccountTitle => 'Account & subscription';

  @override
  String get helpCenterSectionCoachTitle => 'AI Coach & meal ideas';

  @override
  String get helpCenterSectionMealsTitle => 'Meals & AI analysis';

  @override
  String get helpCenterSectionRemindersTitle => 'Reminders & notifications';

  @override
  String get localAiSettingsCancelButton => 'Cancel';

  @override
  String get localAiSettingsDeleteButton => 'Delete';

  @override
  String get localAiSettingsDeleteDialogBody =>
      'The model will be deleted from your phone. AI features will switch back to cloud mode.';

  @override
  String get localAiSettingsDeleteDialogTitle => 'Delete the AI model';

  @override
  String get localAiSettingsDeleteModelButton => 'Delete the model';

  @override
  String get localAiSettingsDownloadButton => 'Download';

  @override
  String localAiSettingsDownloadDialogBody(String size) {
    return 'The model is about $size. We recommend a Wi-Fi connection for this download.';
  }

  @override
  String get localAiSettingsDownloadDialogTitle => 'Download the AI model';

  @override
  String localAiSettingsDownloadFailedError(String error) {
    return 'Download failed: $error';
  }

  @override
  String localAiSettingsDownloadProgressLabel(String percent) {
    return '$percent%';
  }

  @override
  String get localAiSettingsEnableLabel => 'Enable on-device AI';

  @override
  String get localAiSettingsIntro =>
      'Process your meal photos and coach messages right on your phone, with no connection needed and without using the app\'s shared AI quota. It\'s optional: without it, everything keeps working via the cloud like today.';

  @override
  String get localAiSettingsLoadError =>
      'We couldn\'t load your on-device AI settings.';

  @override
  String get localAiSettingsModelDownloadedLabel => 'Model downloaded';

  @override
  String get localAiSettingsModelNotDownloadedLabel => 'Model not downloaded';

  @override
  String get localAiSettingsTitle => 'On-device AI';

  @override
  String get loginContinueWithDiscord => 'Continue with Discord';

  @override
  String get loginDividerOrContinueWith => 'OR CONTINUE WITH';

  @override
  String get loginEmailHint => 'name@example.com';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginErrorFillAllFields => 'Please fill in all fields.';

  @override
  String get loginForgotPasswordLink => 'Forgot your password?';

  @override
  String get loginHeaderLabel => 'LOG IN';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSignupPrompt => 'No account yet? Sign up';

  @override
  String get loginSubmitButton => 'Log in';

  @override
  String get loginSubtitle => 'Log in to track your goals';

  @override
  String get loginWelcomeBackTitle => 'Welcome back';

  @override
  String get mealAnalysisAddIngredientButton => 'Add an ingredient';

  @override
  String get mealAnalysisAddIngredientSheetTitle => 'Add an ingredient';

  @override
  String get mealAnalysisAddIngredientSubtitle =>
      'Fill in the values for the portion you\'re adding.';

  @override
  String get mealAnalysisBadgeAi => 'Identified by AI';

  @override
  String get mealAnalysisBadgeBarcode => 'Found via barcode';

  @override
  String get mealAnalysisBadgeGluc => 'CARB';

  @override
  String get mealAnalysisBadgeLip => 'FAT';

  @override
  String get mealAnalysisBadgeProt => 'PROT';

  @override
  String get mealAnalysisDefaultMealName => 'AI Meal';

  @override
  String get mealAnalysisErrorCaloriesInvalid =>
      'Enter the calories for this portion.';

  @override
  String get mealAnalysisErrorNameRequired => 'Enter the ingredient\'s name.';

  @override
  String get mealAnalysisErrorTitle => 'Oops!';

  @override
  String get mealAnalysisErrorWeightInvalid => 'Enter a valid weight (in g).';

  @override
  String get mealAnalysisFieldCaloriesLabel => 'Calories';

  @override
  String get mealAnalysisFieldNameLabel => 'Ingredient name';

  @override
  String get mealAnalysisFieldWeightLabel => 'Weight';

  @override
  String mealAnalysisGramsValue(String value) {
    return '${value}g';
  }

  @override
  String get mealAnalysisHowItWorksBody =>
      'Our AI identifies the ingredients on your plate and estimates their nutritional values. Tweak the quantities with + / - if needed, remove an ingredient with the trash icon, then confirm to save it to your daily log.';

  @override
  String get mealAnalysisHowItWorksConfirm => 'Got it';

  @override
  String get mealAnalysisHowItWorksTitle => 'How does it work?';

  @override
  String get mealAnalysisIngredientsSubtitle =>
      'Adjust the quantities if needed';

  @override
  String get mealAnalysisIngredientsTitle => 'Ingredients';

  @override
  String mealAnalysisKcalValue(String value) {
    return '$value kcal';
  }

  @override
  String get mealAnalysisLoadingBarcode => 'Looking up the product...';

  @override
  String get mealAnalysisLoadingHint =>
      'This usually takes just a few seconds.';

  @override
  String get mealAnalysisLoadingLabel => 'AI is reading the product label...';

  @override
  String get mealAnalysisLoadingPlate => 'AI is analyzing your plate...';

  @override
  String get mealAnalysisMacroCarbs => 'Carbs';

  @override
  String get mealAnalysisMacroFat => 'Fat';

  @override
  String get mealAnalysisMacroFiber => 'Fiber';

  @override
  String get mealAnalysisMacroProtein => 'Protein';

  @override
  String get mealAnalysisMacroSatFat => 'Sat.';

  @override
  String get mealAnalysisMacroSugar => 'Sugar';

  @override
  String get mealAnalysisNutritionSummaryTitle => 'NUTRITION SUMMARY';

  @override
  String get mealAnalysisRetryButton => 'Try again';

  @override
  String get mealAnalysisSaveButton => 'Confirm and save';

  @override
  String get mealAnalysisSaveSuccessSnackbar => 'Meal saved successfully!';

  @override
  String get mealAnalysisSubmitButton => 'Add';

  @override
  String get mealAnalysisTitleMeal => 'MEAL ANALYSIS';

  @override
  String get mealAnalysisTitleProduct => 'PRODUCT ANALYSIS';

  @override
  String get mealAnalysisTotalKcalLabel => 'TOTAL KCAL';

  @override
  String get mealAnalysisUnitGrams => 'g';

  @override
  String get mealAnalysisUnitKcal => 'kcal';

  @override
  String mealAnalysisWeightValue(String value) {
    return '$value G';
  }

  @override
  String get mealSuggestionCardGlucLabel => 'GLUC';

  @override
  String mealSuggestionCardGramsValue(String value) {
    return '${value}g';
  }

  @override
  String mealSuggestionCardKcalLabel(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get mealSuggestionCardLipLabel => 'LIP';

  @override
  String get mealSuggestionCardProtLabel => 'PROT';

  @override
  String mealSuggestionsAdjustPresetMessage(String title) {
    return 'Adjust this meal for my goal: $title';
  }

  @override
  String get mealSuggestionsEmptyMessage =>
      'No meal ideas available right now.';

  @override
  String get mealSuggestionsLoadError =>
      'We couldn\'t generate meal ideas right now.';

  @override
  String get mealSuggestionsRegenerateTooltip => 'Regenerate';

  @override
  String get mealSuggestionsRetryButton => 'Try again';

  @override
  String get mealSuggestionsTitle => 'Meal ideas';

  @override
  String get notificationSettingsAddButton => 'Add';

  @override
  String get notificationSettingsAddSubmitButton => 'Add';

  @override
  String get notificationSettingsCustomRemindersLoadError =>
      'We couldn\'t load your custom reminders.';

  @override
  String get notificationSettingsCustomRemindersTitle => 'CUSTOM REMINDERS';

  @override
  String get notificationSettingsDisabledLabel => 'Off';

  @override
  String get notificationSettingsIntro =>
      'Get a reminder so you remember to log each of your meals.';

  @override
  String get notificationSettingsLoadError =>
      'We couldn\'t load your notification settings.';

  @override
  String get notificationSettingsNameRequiredError =>
      'Give your reminder a name.';

  @override
  String get notificationSettingsNewReminderTitle => 'New reminder';

  @override
  String get notificationSettingsNoCustomReminders =>
      'No custom reminders yet.';

  @override
  String notificationSettingsReminderAtLabel(String time) {
    return 'Reminder at $time';
  }

  @override
  String get notificationSettingsReminderNameHint =>
      'E.g. Snack, Drink water...';

  @override
  String get notificationSettingsReminderNameLabel => 'Reminder name';

  @override
  String notificationSettingsTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsSlotBreakfast => 'Breakfast';

  @override
  String get notificationSettingsSlotLunch => 'Lunch';

  @override
  String get notificationSettingsSlotDinner => 'Dinner';

  @override
  String get notificationSettingsBodyBreakfast =>
      'Don\'t forget to snap a photo of your breakfast to log it!';

  @override
  String get notificationSettingsBodyLunch =>
      'Don\'t forget to snap a photo of your lunch to log it!';

  @override
  String get notificationSettingsBodyDinner =>
      'Don\'t forget to snap a photo of your dinner to log it!';

  @override
  String get nutritionTrends30DaySectionTitle => 'Calorie trend · last 30 days';

  @override
  String get nutritionTrendsCaloriesLabel => 'Calories';

  @override
  String get nutritionTrendsCaloriesSectionTitle => 'Calories · last 7 days';

  @override
  String get nutritionTrendsCarbsLabel => 'Carbs';

  @override
  String get nutritionTrendsDailyAveragesTitle => 'Daily averages';

  @override
  String get nutritionTrendsDayFri => 'Fri';

  @override
  String get nutritionTrendsDayMon => 'Mon';

  @override
  String get nutritionTrendsDaySat => 'Sat';

  @override
  String get nutritionTrendsDaySun => 'Sun';

  @override
  String get nutritionTrendsDayThu => 'Thu';

  @override
  String get nutritionTrendsDayTue => 'Tue';

  @override
  String get nutritionTrendsDayWed => 'Wed';

  @override
  String get nutritionTrendsEmptyState =>
      'Not enough meals logged this week yet to show trends.';

  @override
  String nutritionTrendsErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get nutritionTrendsExtraNutrientsTitle => 'Other nutrients (avg/day)';

  @override
  String get nutritionTrendsFatLabel => 'Fat';

  @override
  String get nutritionTrendsFiberLabel => 'Fiber';

  @override
  String get nutritionTrendsGoProButton => 'Go PRO';

  @override
  String get nutritionTrendsMacroDistributionTitle =>
      'Macro breakdown (average)';

  @override
  String get nutritionTrendsProLockedDescription =>
      'Unlock detailed macros and 7-day nutrition trends.';

  @override
  String get nutritionTrendsProLockedTitle => 'PRO members only';

  @override
  String get nutritionTrendsProteinLabel => 'Protein';

  @override
  String get nutritionTrendsSatFatLabel => 'Sat. fat';

  @override
  String get nutritionTrendsSugarLabel => 'Sugar';

  @override
  String get nutritionTrendsTitle => 'Advanced analytics';

  @override
  String get onboardingAgeSectionLabel => 'Your Age';

  @override
  String get onboardingAgeUnitSuffix => 'yrs';

  @override
  String get onboardingErrorGoalRequired => 'Pick your main goal.';

  @override
  String get onboardingErrorInvalidAge => 'Enter a valid age.';

  @override
  String get onboardingErrorInvalidHeight => 'Enter your height in cm.';

  @override
  String get onboardingErrorInvalidWeight => 'Enter your weight.';

  @override
  String onboardingErrorSaveProfile(String error) {
    return 'Couldn\'t save your profile: $error';
  }

  @override
  String get onboardingErrorSexRequired => 'Pick your sex to continue.';

  @override
  String get onboardingGoalGainMuscle => 'Gain muscle';

  @override
  String get onboardingGoalGainMuscleDescription =>
      'Increase intake to build muscle.';

  @override
  String get onboardingGoalLoseWeight => 'Lose weight';

  @override
  String get onboardingGoalLoseWeightDescription =>
      'Cut calorie intake and burn fat.';

  @override
  String get onboardingGoalMaintain => 'Maintain my weight';

  @override
  String get onboardingGoalMaintainDescription =>
      'Balance your macros for steady health.';

  @override
  String get onboardingGoalSectionLabel => 'What\'s your goal?';

  @override
  String get onboardingHeightSectionLabel => 'Your Height';

  @override
  String get onboardingSexFemale => 'Female';

  @override
  String get onboardingSexMale => 'Male';

  @override
  String get onboardingSexOther => 'Other';

  @override
  String get onboardingSexSectionLabel => 'You are...';

  @override
  String get onboardingStepIndicator => 'Step 1 of 2';

  @override
  String get onboardingSubmitButton => 'Calculate my plan';

  @override
  String get onboardingSubtitle =>
      'This info lets our AI calculate your precise calorie needs.';

  @override
  String get onboardingTitle => 'Let\'s get to know you';

  @override
  String get onboardingWeightSectionLabel => 'Your Weight';

  @override
  String get paywallBadgePopular => 'POPULAR';

  @override
  String get paywallBenefitAdsFreeSubtitle =>
      'A smooth, premium, distraction-free experience.';

  @override
  String get paywallBenefitAdsFreeTitle => 'Ad-free';

  @override
  String get paywallBenefitAnalyticsSubtitle =>
      'Detailed macros and nutrition trends.';

  @override
  String get paywallBenefitAnalyticsTitle => 'Advanced analytics';

  @override
  String get paywallBenefitCoachSubtitle =>
      'Get recommendations tailored to your goal.';

  @override
  String get paywallBenefitCoachTitle => 'Personal meal coach';

  @override
  String get paywallBenefitPhotoSubtitle =>
      'Analyze as many meals as you need, with no limit.';

  @override
  String get paywallBenefitPhotoTitle => 'Unlimited Photo Recognition';

  @override
  String get paywallChooseForfaitLabel => 'CHOOSE YOUR PLAN';

  @override
  String get paywallDemoModeNotice =>
      'Demo mode: purchases are simulated, no real payment is made.';

  @override
  String get paywallHeaderBadge => 'AI-HEALTH-CHEF PRO';

  @override
  String get paywallPeriodMonth => '/ month';

  @override
  String get paywallPeriodWeek => '/ week';

  @override
  String get paywallPeriodYear => '/ year';

  @override
  String get paywallPlanAnnualTitle => 'Annual';

  @override
  String get paywallPlanLifetimeTitle => 'Lifetime';

  @override
  String get paywallPlanMonthlyTitle => 'Monthly';

  @override
  String get paywallPlanWeeklyTitle => 'Weekly';

  @override
  String get paywallPreviewConfigPending =>
      'Preview — RevenueCat setup pending';

  @override
  String get paywallPreviewDemoMode =>
      'Preview — simulated purchase in demo mode';

  @override
  String get paywallRestoreButton => 'Restore purchases';

  @override
  String paywallRestoreError(String error) {
    return 'Couldn\'t restore purchases: $error';
  }

  @override
  String get paywallRestoreNone => 'No active purchase found for this account.';

  @override
  String get paywallRestoreSuccess =>
      'Purchase restored — your PRO access is active.';

  @override
  String paywallSelectionSummary(String title, String price, String period) {
    return 'Selection: $title • $price $period';
  }

  @override
  String get paywallSubtitle =>
      'Unlock your nutrition\'s full potential with cutting-edge AI.';

  @override
  String get paywallTitle => 'Take it to the next level';

  @override
  String get paywallUnlockButton => 'Unlock AI Health Chef PRO';

  @override
  String get profileAboutSubtitle => 'Version and information';

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileAccountSubtitle => 'Personal information';

  @override
  String get profileAccountTitle => 'Account';

  @override
  String get profileActiveBadge => 'Active';

  @override
  String get profileAdvancedAnalyticsSubtitle =>
      'Detailed macros and nutrition trends';

  @override
  String get profileAdvancedAnalyticsTitle => 'Advanced analytics';

  @override
  String get profileAgeLabel => 'Age';

  @override
  String profileAgeValue(int age) {
    return '$age y.o.';
  }

  @override
  String profileCoachSubtitle(String tone) {
    return 'Tone: $tone';
  }

  @override
  String get profileCoachTitle => 'AI Coach';

  @override
  String get profileCurrentWeightLabel => 'Current weight';

  @override
  String get profileDefaultUserName => 'User';

  @override
  String profileDietaryPrefsSubtitleWithAllergies(String dietType, int count) {
    return '$dietType · $count allerg(y/ies)';
  }

  @override
  String get profileDietaryPrefsTitle => 'Dietary preferences';

  @override
  String get profileGoalLabel => 'Goal';

  @override
  String get profileGoalsSubtitle => 'Calories and macros';

  @override
  String get profileGoalsTitle => 'My goals';

  @override
  String get profileHelpCenterSubtitle => 'FAQs, guides and tutorials';

  @override
  String get profileHelpCenterTitle => 'Help center';

  @override
  String get profileLanguageTitle => 'Language';

  @override
  String profileLoadError(String error) {
    return 'Couldn\'t load the profile: $error';
  }

  @override
  String get profileLocalAiSubtitleDefault => 'On-device scan and chat';

  @override
  String get profileLocalAiSubtitleDisabled => 'Disabled';

  @override
  String get profileLocalAiSubtitleEnabled => 'Enabled';

  @override
  String get profileLocalAiSubtitleEnabledNotDownloaded =>
      'Enabled · needs download';

  @override
  String get profileLocalAiTitle => 'On-device AI';

  @override
  String get profileLogoutButton => 'Sign out';

  @override
  String profileLogoutError(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get profileNotificationsSubtitle => 'Meal reminders and tracking';

  @override
  String get profileNotificationsTitle => 'Notifications';

  @override
  String get profileProBadge => 'PRO';

  @override
  String get profileProBadgeHeader => 'Pro';

  @override
  String get profileSectionGeneral => 'GENERAL';

  @override
  String get profileSectionPersonalization => 'PERSONALIZATION';

  @override
  String get profileSectionSupport => 'SUPPORT';

  @override
  String get profileSecurityComingSoonMessage =>
      'Security and privacy settings are coming soon.';

  @override
  String get profileSecuritySubtitle => 'Data and security';

  @override
  String get profileSecurityTitle => 'Security and Privacy';

  @override
  String get profileSubscriptionSubtitle => 'PRO plan and billing';

  @override
  String get profileSubscriptionTitle => 'Subscription';

  @override
  String get profileTargetWeightLabel => 'Target weight';

  @override
  String get profileTermsSubtitle => 'Terms of service and legal notice';

  @override
  String get profileTermsTitle => 'Terms of use';

  @override
  String get profileTitle => 'MY PROFILE';

  @override
  String get profileUnknownUser => 'Unknown user';

  @override
  String get profileVersionText => 'AI Health Chef v1.0.0';

  @override
  String profileWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get signupAlreadyMember => 'Already a member?';

  @override
  String get signupDividerOrSignUpWith => 'OR SIGN UP WITH';

  @override
  String get signupEmailHint => 'john.smith@example.com';

  @override
  String get signupEmailLabel => 'EMAIL ADDRESS';

  @override
  String get signupErrorAcceptTerms => 'You must accept the Terms of Use.';

  @override
  String get signupErrorFillAllFields => 'Please fill in all fields.';

  @override
  String get signupFullNameHint => 'John Smith';

  @override
  String get signupFullNameLabel => 'FULL NAME';

  @override
  String get signupHeaderLabel => 'CREATE AN ACCOUNT';

  @override
  String get signupLoginLink => 'Log in';

  @override
  String get signupPasswordLabel => 'PASSWORD';

  @override
  String get signupSecureDataNotice => 'encrypted & secure data';

  @override
  String get signupSubmitButton => 'Sign up';

  @override
  String get signupSubtitle =>
      'Join us to transform your nutrition with artificial intelligence.';

  @override
  String get signupSuccessCheckEmail =>
      'Account created! Check your email to confirm.';

  @override
  String get signupTermsAcceptance =>
      'I accept the Terms of Use and Privacy Policy';

  @override
  String get termsAppBarTitle => 'Terms of Use';

  @override
  String get termsDraftBanner =>
      'Draft: this document honestly describes the service, but has not yet been reviewed by a legal professional and the publisher\'s legal identity is still to be completed. To be finalized before any public release of the app.';

  @override
  String termsLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get termsSection10Body =>
      'The App is provided \"as is\". The publisher does not guarantee the accuracy, continuous availability, or error-free nature of the service, in particular the AI-generated estimates. Use of the App is at your own sole risk.';

  @override
  String get termsSection10Title => '10. Liability';

  @override
  String termsSection11Body(String supportEmail) {
    return 'You may stop using the App and request the deletion of your account at any time by writing to $supportEmail. The publisher may suspend or delete an account in the event of abusive use or failure to comply with these Terms.';
  }

  @override
  String get termsSection11Title => '11. Termination';

  @override
  String get termsSection12Body =>
      'These Terms may change, in particular as features are added to the App. The version in effect is always the one available within the App.';

  @override
  String get termsSection12Title => '12. Changes to these Terms';

  @override
  String get termsSection13Body => 'These Terms are governed by French law.';

  @override
  String get termsSection13Title => '13. Governing law';

  @override
  String termsSection14Body(String supportEmail) {
    return 'For any question relating to these Terms or your data: $supportEmail.';
  }

  @override
  String get termsSection14Title => '14. Contact';

  @override
  String termsSection1Body(String supportEmail) {
    return 'Publisher: [Publisher name to be completed] — a project currently developed in a personal capacity, with no registered company to date.\nContact: $supportEmail\nData and backend hosting: Supabase Inc. (third-party cloud infrastructure). App distributed via the App Store (Apple) and the Google Play Store.';
  }

  @override
  String get termsSection1Title => '1. Legal notice';

  @override
  String get termsSection2Body =>
      'These Terms of Use (\"Terms\") govern access to and use of the AI Health Chef mobile application (the \"App\"). By creating an account or using the App, you accept these Terms in full.';

  @override
  String get termsSection2Title => '2. Purpose';

  @override
  String get termsSection3Body =>
      'AI Health Chef lets you: track your meals and macronutrients daily; analyze a photo of a meal using artificial intelligence to estimate ingredients and nutritional values; chat with an AI-based conversational nutrition coach; receive personalized meal ideas; set up meal reminders; and, via an optional PRO subscription, unlock additional features.';

  @override
  String get termsSection3Title => '3. Description of the service';

  @override
  String get termsSection4Body =>
      'AI Health Chef provides information and estimates for informational purposes only and does not constitute medical advice, a diagnosis, or a prescription in any way. Calorie, macro, and nutritional goal calculations are general estimates. Consult a doctor or dietitian before making any significant dietary change, particularly in the case of a medical condition, pregnancy, or an eating disorder. The App should not be used as the sole tracking tool in a medical context.';

  @override
  String get termsSection4Title => '4. This is not medical advice';

  @override
  String get termsSection5Body =>
      'Ingredients detected in a photo, estimated nutritional values, coach AI responses, and meal ideas are generated by third-party AI models (currently Google Gemini) and may contain errors, inaccuracies, or approximations. Check and adjust the information before relying on it, particularly in the case of an allergy or dietary restriction.';

  @override
  String get termsSection5Title =>
      '5. Content generated by artificial intelligence';

  @override
  String get termsSection6Body =>
      'Using the App requires creating an account. You are responsible for the accuracy of the information provided and for keeping your login credentials confidential. Any activity carried out from your account is presumed to have been performed by you.';

  @override
  String get termsSection6Title => '6. User account';

  @override
  String get termsSection7Body =>
      'Some features are reserved for subscribed (\"PRO\") users. The purchase, automatic renewal, and cancellation of the subscription are entirely managed by your device\'s payment platform (App Store or Google Play), not directly by the publisher. The subscription renews automatically unless canceled at least 24 hours before the end of the current period, from your Apple or Google account settings. Refund requests are subject to Apple\'s/Google\'s policies, not the publisher\'s.';

  @override
  String get termsSection7Title => '7. PRO subscription';

  @override
  String termsSection8Body(String supportEmail) {
    return 'The App processes, in particular: your email and password (authentication); health profile data (sex, age, weight, height, goal); the meal photos you take and the associated nutritional data; your profile picture; and your chat history with the AI coach. This data is used solely to provide the service (calculating your goals, analyzing your meals, tracking your history) and is hosted by Supabase. Meal photos are sent to Google (Gemini model) for the duration of the analysis. No data is sold to third parties. You may request access to, correction of, or deletion of your data at any time by writing to $supportEmail.';
  }

  @override
  String get termsSection8Title => '8. Personal data';

  @override
  String get termsSection9Body =>
      'The name, logo, and graphic elements of the App belong to the publisher. The content you create (photos, messages) remains your property; you grant the publisher the right to process it solely for the purpose of operating the service (e.g. sending it to an AI provider for analysis).';

  @override
  String get termsSection9Title => '9. Intellectual property';

  @override
  String get svcErrorCompressImage => 'Couldn\'t compress the image.';

  @override
  String svcErrorAnalyzeMeal(String error) {
    return 'AI analysis error: $error';
  }

  @override
  String svcErrorAnalyzeProduct(String error) {
    return 'Product analysis error: $error';
  }

  @override
  String svcErrorCoachChat(String error) {
    return 'Error connecting to the AI Coach: $error';
  }

  @override
  String svcErrorMealSuggestions(String error) {
    return 'Error generating meal ideas: $error';
  }

  @override
  String get svcErrorAuthRequired => 'You must be signed in to do this.';

  @override
  String get svcErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String svcErrorSignup(String error) {
    return 'Sign-up error: $error';
  }

  @override
  String svcErrorSaveProfile(String error) {
    return 'Error saving profile: $error';
  }

  @override
  String svcErrorSavePreferences(String error) {
    return 'Error saving preferences: $error';
  }

  @override
  String svcErrorSaveCoachTone(String error) {
    return 'Error saving Coach tone: $error';
  }

  @override
  String get svcErrorProcessImage => 'Couldn\'t process the image.';

  @override
  String svcErrorUploadPhoto(String error) {
    return 'Error uploading photo: $error';
  }

  @override
  String svcErrorFetchProfile(String error) {
    return 'Error fetching profile: $error';
  }

  @override
  String get svcErrorResetPassword => 'Error sending the email.';

  @override
  String svcErrorOAuth(String provider, String error) {
    return 'Error signing in with $provider: $error';
  }

  @override
  String svcErrorProductLookupNetwork(String error) {
    return 'Couldn\'t reach the product database: $error';
  }

  @override
  String svcErrorProductLookupHttp(String status) {
    return 'Network error while searching for the product ($status).';
  }

  @override
  String get svcErrorProductNotFound =>
      'Product not found for this barcode. Try taking a photo of the product instead, or add it manually.';

  @override
  String svcErrorLocalAiUnexpectedResponse(String response) {
    return 'Unexpected local AI response: $response';
  }

  @override
  String get svcErrorHuggingFaceToken =>
      'Couldn\'t retrieve the Hugging Face token.';
}
