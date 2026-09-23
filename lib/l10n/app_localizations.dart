import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef'**
  String get appTitle;

  /// No description provided for @bmiCategoryUnderweight.
  ///
  /// In fr, this message translates to:
  /// **'Insuffisance pondérale'**
  String get bmiCategoryUnderweight;

  /// No description provided for @bmiCategoryNormal.
  ///
  /// In fr, this message translates to:
  /// **'Corpulence normale'**
  String get bmiCategoryNormal;

  /// No description provided for @bmiCategoryOverweight.
  ///
  /// In fr, this message translates to:
  /// **'Surpoids'**
  String get bmiCategoryOverweight;

  /// No description provided for @bmiCategoryObese.
  ///
  /// In fr, this message translates to:
  /// **'Obésité'**
  String get bmiCategoryObese;

  /// No description provided for @aboutAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutAppBarTitle;

  /// No description provided for @aboutAppName.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef'**
  String get aboutAppName;

  /// No description provided for @aboutContactLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get aboutContactLinkTitle;

  /// No description provided for @aboutCopyright.
  ///
  /// In fr, this message translates to:
  /// **'© {year} AI Health Chef'**
  String aboutCopyright(int year);

  /// No description provided for @aboutDescription.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef t’aide à suivre tes repas et tes objectifs nutritionnels : scanne ton assiette pour une estimation automatique des calories et macros, échange avec un coach IA, reçois des idées de repas personnalisées et des rappels pour ne rien oublier.'**
  String get aboutDescription;

  /// No description provided for @aboutHelpCenterLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d’aide'**
  String get aboutHelpCenterLinkTitle;

  /// No description provided for @aboutMailtoSubject.
  ///
  /// In fr, this message translates to:
  /// **'Contact AI Health Chef'**
  String get aboutMailtoSubject;

  /// No description provided for @aboutNoMailAppSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Aucune app mail configurée. Écris-nous à {supportEmail}.'**
  String aboutNoMailAppSnackbar(String supportEmail);

  /// No description provided for @aboutTermsLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get aboutTermsLinkTitle;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String aboutVersionLabel(String version, String buildNumber);

  /// No description provided for @aboutVersionLoading.
  ///
  /// In fr, this message translates to:
  /// **'…'**
  String get aboutVersionLoading;

  /// No description provided for @accountAgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get accountAgeLabel;

  /// No description provided for @accountAgeSuffix.
  ///
  /// In fr, this message translates to:
  /// **'ans'**
  String get accountAgeSuffix;

  /// No description provided for @accountBmiLabel.
  ///
  /// In fr, this message translates to:
  /// **'IMC : {label}'**
  String accountBmiLabel(String label);

  /// No description provided for @accountBmiPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne ton poids et ta taille pour voir ton IMC.'**
  String get accountBmiPlaceholder;

  /// No description provided for @accountBmiRangeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plage {label} : {range}'**
  String accountBmiRangeLabel(String label, String range);

  /// No description provided for @accountChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get accountChooseFromGallery;

  /// No description provided for @accountCurrentWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids actuel'**
  String get accountCurrentWeightLabel;

  /// No description provided for @accountErrorInvalidAge.
  ///
  /// In fr, this message translates to:
  /// **'Entre un âge valide.'**
  String get accountErrorInvalidAge;

  /// No description provided for @accountErrorInvalidCurrentWeight.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton poids actuel.'**
  String get accountErrorInvalidCurrentWeight;

  /// No description provided for @accountErrorInvalidHeight.
  ///
  /// In fr, this message translates to:
  /// **'Entre ta taille en cm.'**
  String get accountErrorInvalidHeight;

  /// No description provided for @accountErrorInvalidTargetWeight.
  ///
  /// In fr, this message translates to:
  /// **'Entre un poids cible valide.'**
  String get accountErrorInvalidTargetWeight;

  /// No description provided for @accountErrorNameEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ton nom ne peut pas être vide.'**
  String get accountErrorNameEmpty;

  /// No description provided for @accountFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get accountFullNameLabel;

  /// No description provided for @accountGoalGainMuscle.
  ///
  /// In fr, this message translates to:
  /// **'Prise de masse'**
  String get accountGoalGainMuscle;

  /// No description provided for @accountGoalLoseWeight.
  ///
  /// In fr, this message translates to:
  /// **'Perte de poids'**
  String get accountGoalLoseWeight;

  /// No description provided for @accountGoalMaintain.
  ///
  /// In fr, this message translates to:
  /// **'Maintien'**
  String get accountGoalMaintain;

  /// No description provided for @accountHeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get accountHeightLabel;

  /// No description provided for @accountHeightSuffix.
  ///
  /// In fr, this message translates to:
  /// **'cm'**
  String get accountHeightSuffix;

  /// No description provided for @accountLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le profil : {error}'**
  String accountLoadError(String error);

  /// No description provided for @accountMainGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif principal'**
  String get accountMainGoalLabel;

  /// No description provided for @accountSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get accountSaveButton;

  /// No description provided for @accountSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer : {error}'**
  String accountSaveError(String error);

  /// No description provided for @accountSexFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get accountSexFemale;

  /// No description provided for @accountSexLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get accountSexLabel;

  /// No description provided for @accountSexMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get accountSexMale;

  /// No description provided for @accountSexOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get accountSexOther;

  /// No description provided for @accountTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get accountTakePhoto;

  /// No description provided for @accountTargetWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids cible'**
  String get accountTargetWeightLabel;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'MON COMPTE'**
  String get accountTitle;

  /// No description provided for @accountUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get accountUpdateSuccess;

  /// No description provided for @accountWeightSuffix.
  ///
  /// In fr, this message translates to:
  /// **'kg'**
  String get accountWeightSuffix;

  /// No description provided for @barcodeScannerHintCaption.
  ///
  /// In fr, this message translates to:
  /// **'Cadre le code-barres du produit'**
  String get barcodeScannerHintCaption;

  /// No description provided for @barcodeScannerTitleCaption.
  ///
  /// In fr, this message translates to:
  /// **'SCANNER UN PRODUIT'**
  String get barcodeScannerTitleCaption;

  /// No description provided for @cameraCaptureAiAnalysisCaption.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE NUTRITIONNELLE IA'**
  String get cameraCaptureAiAnalysisCaption;

  /// No description provided for @cameraCaptureBackButton.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get cameraCaptureBackButton;

  /// No description provided for @cameraCaptureCameraErrorFallback.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir la caméra.'**
  String get cameraCaptureCameraErrorFallback;

  /// No description provided for @cameraCaptureCaptureFailedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la capture : {error}'**
  String cameraCaptureCaptureFailedMessage(String error);

  /// No description provided for @cameraCaptureChooseGalleryPhotoButton.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo depuis la galerie'**
  String get cameraCaptureChooseGalleryPhotoButton;

  /// No description provided for @cameraCaptureFrameMealHint.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez votre plat au centre'**
  String get cameraCaptureFrameMealHint;

  /// No description provided for @cameraCaptureFrameProductHint.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez l’étiquette du produit'**
  String get cameraCaptureFrameProductHint;

  /// No description provided for @cameraCaptureGalleryButton.
  ///
  /// In fr, this message translates to:
  /// **'GALERIE'**
  String get cameraCaptureGalleryButton;

  /// No description provided for @cameraCaptureGalleryOpenError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir la galerie : {error}'**
  String cameraCaptureGalleryOpenError(String error);

  /// No description provided for @cameraCaptureHelpBody.
  ///
  /// In fr, this message translates to:
  /// **'Centre ton assiette dans le cercle, garde l’appareil stable puis appuie sur le déclencheur. Notre IA analyse automatiquement les aliments et leurs valeurs nutritionnelles.'**
  String get cameraCaptureHelpBody;

  /// No description provided for @cameraCaptureHelpDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get cameraCaptureHelpDismiss;

  /// No description provided for @cameraCaptureHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get cameraCaptureHelpTitle;

  /// No description provided for @cameraCaptureModeMeal.
  ///
  /// In fr, this message translates to:
  /// **'Repas'**
  String get cameraCaptureModeMeal;

  /// No description provided for @cameraCaptureModeProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get cameraCaptureModeProduct;

  /// No description provided for @cameraCaptureModeScanner.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get cameraCaptureModeScanner;

  /// No description provided for @cameraCaptureNoCameraMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune caméra disponible sur cet appareil.'**
  String get cameraCaptureNoCameraMessage;

  /// No description provided for @cameraCaptureOpenCameraError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir la caméra : {error}'**
  String cameraCaptureOpenCameraError(String error);

  /// No description provided for @cameraCaptureRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get cameraCaptureRetryButton;

  /// No description provided for @checkoutAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser la commande'**
  String get checkoutAppBarTitle;

  /// No description provided for @checkoutConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer • {price} {period}'**
  String checkoutConfirmButton(String price, String period);

  /// No description provided for @checkoutDefaultPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement PRO'**
  String get checkoutDefaultPlanTitle;

  /// No description provided for @checkoutDemoModeNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo : cet achat est simulé, aucun paiement ni compte App Store / Google Play n\'est sollicité.'**
  String get checkoutDemoModeNotice;

  /// No description provided for @checkoutOrderSummaryBrand.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef PRO'**
  String get checkoutOrderSummaryBrand;

  /// No description provided for @checkoutOrderSummaryDemoNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo — l\'achat sera simulé, aucun paiement réel'**
  String get checkoutOrderSummaryDemoNotice;

  /// No description provided for @checkoutPaymentMethodLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOYEN DE PAIEMENT'**
  String get checkoutPaymentMethodLabel;

  /// No description provided for @checkoutPendingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Achat effectué, en attente de confirmation.'**
  String get checkoutPendingConfirmation;

  /// No description provided for @checkoutPlanLabel.
  ///
  /// In fr, this message translates to:
  /// **'Forfait'**
  String get checkoutPlanLabel;

  /// No description provided for @checkoutPurchaseError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'achat : {error}'**
  String checkoutPurchaseError(String error);

  /// No description provided for @checkoutRenewalDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'L\'abonnement se renouvelle automatiquement sauf annulation au moins 24h avant la fin de la période, depuis les réglages de ton compte App Store ou Google Play.'**
  String get checkoutRenewalDisclaimer;

  /// No description provided for @checkoutRenewalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement'**
  String get checkoutRenewalLabel;

  /// No description provided for @checkoutRenewalValue.
  ///
  /// In fr, this message translates to:
  /// **'Automatique, résiliable à tout moment'**
  String get checkoutRenewalValue;

  /// No description provided for @checkoutSecurePaymentNotice.
  ///
  /// In fr, this message translates to:
  /// **'Paiement géré en toute sécurité par l\'App Store / Google Play. Aucune information bancaire n\'est demandée dans l\'application.'**
  String get checkoutSecurePaymentNotice;

  /// No description provided for @checkoutSuccessDemo.
  ///
  /// In fr, this message translates to:
  /// **'Achat simulé (mode démo)\nAccès PRO débloqué !'**
  String get checkoutSuccessDemo;

  /// No description provided for @checkoutSuccessReal.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement activé !\nBienvenue dans AI Health Chef PRO.'**
  String get checkoutSuccessReal;

  /// No description provided for @checkoutSummaryLabel.
  ///
  /// In fr, this message translates to:
  /// **'RÉCAPITULATIF'**
  String get checkoutSummaryLabel;

  /// No description provided for @checkoutTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get checkoutTotalLabel;

  /// No description provided for @coachAdjustMealPresetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ajuste ce repas pour mon objectif: {mealTitle}'**
  String coachAdjustMealPresetMessage(String mealTitle);

  /// No description provided for @coachCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get coachCancelButton;

  /// No description provided for @coachCarbsLabel.
  ///
  /// In fr, this message translates to:
  /// **'GLUCIDES'**
  String get coachCarbsLabel;

  /// No description provided for @coachDailyObjectiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'OBJECTIF QUOTIDIEN'**
  String get coachDailyObjectiveTitle;

  /// No description provided for @coachFatLabel.
  ///
  /// In fr, this message translates to:
  /// **'LIPIDES'**
  String get coachFatLabel;

  /// No description provided for @coachGoalMaintainLabel.
  ///
  /// In fr, this message translates to:
  /// **'Maintien'**
  String get coachGoalMaintainLabel;

  /// No description provided for @coachHeaderTitle.
  ///
  /// In fr, this message translates to:
  /// **'COACH NUTRITION'**
  String get coachHeaderTitle;

  /// No description provided for @coachInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta question...'**
  String get coachInputHint;

  /// No description provided for @coachKcalUnitLabel.
  ///
  /// In fr, this message translates to:
  /// **' kcal'**
  String get coachKcalUnitLabel;

  /// No description provided for @coachMealSuggestionsEmptyText.
  ///
  /// In fr, this message translates to:
  /// **'Aucune idée de repas disponible pour le moment.'**
  String get coachMealSuggestionsEmptyText;

  /// No description provided for @coachMealSuggestionsErrorText.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer des idées de repas pour le moment.'**
  String get coachMealSuggestionsErrorText;

  /// No description provided for @coachNeedValueGrams.
  ///
  /// In fr, this message translates to:
  /// **'{current}/{target}g'**
  String coachNeedValueGrams(int current, int target);

  /// No description provided for @coachNeedsTitle.
  ///
  /// In fr, this message translates to:
  /// **'VOS BESOINS'**
  String get coachNeedsTitle;

  /// No description provided for @coachNextMealIdeasTitle.
  ///
  /// In fr, this message translates to:
  /// **'Idées Prochain Repas'**
  String get coachNextMealIdeasTitle;

  /// No description provided for @coachPersonalizationAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coach IA'**
  String get coachPersonalizationAppBarTitle;

  /// No description provided for @coachPersonalizationIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le ton que le Coach IA adopte dans ses réponses.'**
  String get coachPersonalizationIntro;

  /// No description provided for @coachPersonalizationToneBienveillantDescription.
  ///
  /// In fr, this message translates to:
  /// **'Doux, rassurant, sans jugement sur tes écarts.'**
  String get coachPersonalizationToneBienveillantDescription;

  /// No description provided for @coachPersonalizationToneBienveillantLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bienveillant & calme'**
  String get coachPersonalizationToneBienveillantLabel;

  /// No description provided for @coachPersonalizationToneDirectDescription.
  ///
  /// In fr, this message translates to:
  /// **'Droit au but, des conseils actionnables sans détour.'**
  String get coachPersonalizationToneDirectDescription;

  /// No description provided for @coachPersonalizationToneDirectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Direct & concis'**
  String get coachPersonalizationToneDirectLabel;

  /// No description provided for @coachPersonalizationToneHumoristiqueDescription.
  ///
  /// In fr, this message translates to:
  /// **'Léger et avec humour, tout en restant utile.'**
  String get coachPersonalizationToneHumoristiqueDescription;

  /// No description provided for @coachPersonalizationToneHumoristiqueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Humoristique'**
  String get coachPersonalizationToneHumoristiqueLabel;

  /// No description provided for @coachPersonalizationToneMotivantDescription.
  ///
  /// In fr, this message translates to:
  /// **'Encourageant, dynamique, te pousse à avancer.'**
  String get coachPersonalizationToneMotivantDescription;

  /// No description provided for @coachPersonalizationToneMotivantLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motivant & énergique'**
  String get coachPersonalizationToneMotivantLabel;

  /// No description provided for @coachPromptFatLossLabel.
  ///
  /// In fr, this message translates to:
  /// **'Perte de gras'**
  String get coachPromptFatLossLabel;

  /// No description provided for @coachPromptFatLossMessage.
  ///
  /// In fr, this message translates to:
  /// **'Comment optimiser ma perte de gras aujourd\'hui ?'**
  String get coachPromptFatLossMessage;

  /// No description provided for @coachPromptIdeasLabel.
  ///
  /// In fr, this message translates to:
  /// **'Idées repas'**
  String get coachPromptIdeasLabel;

  /// No description provided for @coachPromptIdeasMessage.
  ///
  /// In fr, this message translates to:
  /// **'Donne-moi une idée de repas riche en protéines.'**
  String get coachPromptIdeasMessage;

  /// No description provided for @coachPromptPostWorkoutLabel.
  ///
  /// In fr, this message translates to:
  /// **'Après sport'**
  String get coachPromptPostWorkoutLabel;

  /// No description provided for @coachPromptPostWorkoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Que manger après ma séance pour récupérer ?'**
  String get coachPromptPostWorkoutMessage;

  /// No description provided for @coachProteinLabel.
  ///
  /// In fr, this message translates to:
  /// **'PROTÉINES'**
  String get coachProteinLabel;

  /// No description provided for @coachRealtimeBannerLabel.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE EN TEMPS RÉEL'**
  String get coachRealtimeBannerLabel;

  /// No description provided for @coachRemainingKcalText.
  ///
  /// In fr, this message translates to:
  /// **'Il vous reste {remainingKcal} kcal pour atteindre votre objectif de {goalLabel}.'**
  String coachRemainingKcalText(int remainingKcal, String goalLabel);

  /// No description provided for @coachResetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get coachResetButton;

  /// No description provided for @coachResetDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Tout l\'historique de discussion avec le coach sera supprimé.'**
  String get coachResetDialogContent;

  /// No description provided for @coachResetDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la conversation ?'**
  String get coachResetDialogTitle;

  /// No description provided for @coachResetTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la conversation'**
  String get coachResetTooltip;

  /// No description provided for @coachRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get coachRetryButton;

  /// No description provided for @coachSeeAllButton.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get coachSeeAllButton;

  /// No description provided for @coachSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pose une question sur tes repas'**
  String get coachSheetSubtitle;

  /// No description provided for @coachTipFatLossText.
  ///
  /// In fr, this message translates to:
  /// **'Pour optimiser votre perte de gras, privilégiez des sources de protéines maigres comme le blanc de poulet ou le tofu pour votre prochain repas.'**
  String get coachTipFatLossText;

  /// No description provided for @coachTipTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseil du Chef IA'**
  String get coachTipTitle;

  /// No description provided for @coachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coach IA'**
  String get coachTitle;

  /// No description provided for @comingSoonDefaultMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité arrive prochainement.'**
  String get comingSoonDefaultMessage;

  /// No description provided for @comingSoonDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoonDefaultTitle;

  /// No description provided for @dashboardBmiLabel.
  ///
  /// In fr, this message translates to:
  /// **'IMC : {label}'**
  String dashboardBmiLabel(String label);

  /// No description provided for @dashboardBmiRangeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plage {label} : {range}'**
  String dashboardBmiRangeLabel(String label, String range);

  /// No description provided for @dashboardCalorieGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **' Objectif: {kcal}'**
  String dashboardCalorieGoalLabel(int kcal);

  /// No description provided for @dashboardCarbsLabel.
  ///
  /// In fr, this message translates to:
  /// **'GLUCIDES'**
  String get dashboardCarbsLabel;

  /// No description provided for @dashboardEmptyMealsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun repas enregistré aujourd\'hui. Scannez votre première assiette !'**
  String get dashboardEmptyMealsMessage;

  /// No description provided for @dashboardFatLabel.
  ///
  /// In fr, this message translates to:
  /// **'LIPIDES'**
  String get dashboardFatLabel;

  /// No description provided for @dashboardKcalRemainingLabel.
  ///
  /// In fr, this message translates to:
  /// **'KCAL RESTANT'**
  String get dashboardKcalRemainingLabel;

  /// No description provided for @dashboardMealCaloriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'{kcal} kcal'**
  String dashboardMealCaloriesLabel(int kcal);

  /// No description provided for @dashboardMealJournalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Journal des repas'**
  String get dashboardMealJournalTitle;

  /// No description provided for @dashboardMealsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String dashboardMealsLoadError(String error);

  /// No description provided for @dashboardProteinLabel.
  ///
  /// In fr, this message translates to:
  /// **'PROTÉINES'**
  String get dashboardProteinLabel;

  /// No description provided for @dashboardTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dashboardTodayTitle;

  /// No description provided for @dietaryPreferencesAllergiesDescription.
  ///
  /// In fr, this message translates to:
  /// **'Elles seront évitées dans les idées de repas proposées par l’IA. Ne remplace pas la vigilance en cas d’allergie sévère.'**
  String get dietaryPreferencesAllergiesDescription;

  /// No description provided for @dietaryPreferencesAllergiesSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'ALLERGIES & INTOLÉRANCES'**
  String get dietaryPreferencesAllergiesSectionTitle;

  /// No description provided for @dietaryPreferencesDietHalal.
  ///
  /// In fr, this message translates to:
  /// **'Halal'**
  String get dietaryPreferencesDietHalal;

  /// No description provided for @dietaryPreferencesDietKosher.
  ///
  /// In fr, this message translates to:
  /// **'Kasher'**
  String get dietaryPreferencesDietKosher;

  /// No description provided for @dietaryPreferencesDietNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune restriction'**
  String get dietaryPreferencesDietNone;

  /// No description provided for @dietaryPreferencesDietPescetarian.
  ///
  /// In fr, this message translates to:
  /// **'Pescétarien'**
  String get dietaryPreferencesDietPescetarian;

  /// No description provided for @dietaryPreferencesDietSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÉGIME'**
  String get dietaryPreferencesDietSectionTitle;

  /// No description provided for @dietaryPreferencesDietVegan.
  ///
  /// In fr, this message translates to:
  /// **'Végétalien'**
  String get dietaryPreferencesDietVegan;

  /// No description provided for @dietaryPreferencesDietVegetarian.
  ///
  /// In fr, this message translates to:
  /// **'Végétarien'**
  String get dietaryPreferencesDietVegetarian;

  /// No description provided for @dietaryPreferencesOtherAllergyHint.
  ///
  /// In fr, this message translates to:
  /// **'Autre allergie...'**
  String get dietaryPreferencesOtherAllergyHint;

  /// No description provided for @dietaryPreferencesSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get dietaryPreferencesSaveButton;

  /// No description provided for @dietaryPreferencesSavedSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Préférences enregistrées !'**
  String get dietaryPreferencesSavedSnackbar;

  /// No description provided for @dietaryPreferencesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences alimentaires'**
  String get dietaryPreferencesTitle;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@email.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordErrorEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre adresse e-mail.'**
  String get forgotPasswordErrorEmailRequired;

  /// No description provided for @forgotPasswordSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPasswordSubmitButton;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ne vous inquiétez pas, cela arrive.\nEntrez votre email pour recevoir un\nlien de réinitialisation.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Lien de réinitialisation envoyé ! Vérifiez vos emails.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @helpCenterAccountQ1Answer.
  ///
  /// In fr, this message translates to:
  /// **'Va dans Profil > Compte pour modifier tes informations, ou Profil > Mes objectifs pour ajuster ton objectif (perte de poids, prise de muscle, maintien) et tes données physiques.'**
  String get helpCenterAccountQ1Answer;

  /// No description provided for @helpCenterAccountQ1Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mon profil ou mes objectifs ?'**
  String get helpCenterAccountQ1Question;

  /// No description provided for @helpCenterAccountQ2Answer.
  ///
  /// In fr, this message translates to:
  /// **'Ton abonnement est géré directement par l’App Store ou le Google Play Store (selon ton appareil), pas par l’app elle-même. Rends-toi dans les réglages d’abonnements de ton compte Apple/Google pour le modifier ou le résilier.'**
  String get helpCenterAccountQ2Answer;

  /// No description provided for @helpCenterAccountQ2Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment gérer ou annuler mon abonnement PRO ?'**
  String get helpCenterAccountQ2Question;

  /// No description provided for @helpCenterAccountQ3Answer.
  ///
  /// In fr, this message translates to:
  /// **'Écris-nous à {supportEmail} depuis l’adresse email associée à ton compte, on s’occupe de la suppression de tes données.'**
  String helpCenterAccountQ3Answer(String supportEmail);

  /// No description provided for @helpCenterAccountQ3Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment supprimer mon compte ?'**
  String get helpCenterAccountQ3Question;

  /// No description provided for @helpCenterAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d’aide'**
  String get helpCenterAppBarTitle;

  /// No description provided for @helpCenterCoachQ1Answer.
  ///
  /// In fr, this message translates to:
  /// **'Depuis l’onglet Coach, appuie sur le bouton \"Coach IA\" en bas de l’écran pour ouvrir le chat. Tu peux lui poser des questions sur ta nutrition, tes objectifs ou lui demander des conseils.'**
  String get helpCenterCoachQ1Answer;

  /// No description provided for @helpCenterCoachQ1Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment parler au Coach IA ?'**
  String get helpCenterCoachQ1Question;

  /// No description provided for @helpCenterCoachQ2Answer.
  ///
  /// In fr, this message translates to:
  /// **'L’onglet Coach propose des idées de repas générées selon ton profil et ton objectif. Appuie sur \"Tout voir\" pour la liste complète, puis sur l’icône de rafraîchissement (ou tire l’écran vers le bas) pour en générer de nouvelles.'**
  String get helpCenterCoachQ2Answer;

  /// No description provided for @helpCenterCoachQ2Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment obtenir de nouvelles idées de repas ?'**
  String get helpCenterCoachQ2Question;

  /// No description provided for @helpCenterContactButtonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get helpCenterContactButtonLabel;

  /// No description provided for @helpCenterMailtoSubject.
  ///
  /// In fr, this message translates to:
  /// **'Question AI Health Chef'**
  String get helpCenterMailtoSubject;

  /// No description provided for @helpCenterMealsQ1Answer.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le Dashboard, appuie sur le bouton caméra en bas à droite pour prendre en photo ton assiette. L’IA identifie les ingrédients et estime les calories et macros ; tu peux ajuster les quantités, ajouter ou retirer un ingrédient avant de valider.'**
  String get helpCenterMealsQ1Answer;

  /// No description provided for @helpCenterMealsQ1Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment enregistrer un repas ?'**
  String get helpCenterMealsQ1Question;

  /// No description provided for @helpCenterMealsQ2Answer.
  ///
  /// In fr, this message translates to:
  /// **'L’analyse est faite par un modèle d’IA (Google Gemini) à partir de la photo : c’est une estimation, pas une mesure exacte. Ajuste les quantités si besoin, ou ajoute un ingrédient manuellement avec ses valeurs exactes via \"Ajouter un ingrédient\".'**
  String get helpCenterMealsQ2Answer;

  /// No description provided for @helpCenterMealsQ2Question.
  ///
  /// In fr, this message translates to:
  /// **'L’estimation des calories est-elle exacte ?'**
  String get helpCenterMealsQ2Question;

  /// No description provided for @helpCenterMealsQ3Answer.
  ///
  /// In fr, this message translates to:
  /// **'Le Dashboard affiche le \"Journal des repas\" du jour, avec les totaux de calories et macros. Il se réinitialise chaque jour à minuit.'**
  String get helpCenterMealsQ3Answer;

  /// No description provided for @helpCenterMealsQ3Question.
  ///
  /// In fr, this message translates to:
  /// **'Où voir les repas que j’ai enregistrés aujourd’hui ?'**
  String get helpCenterMealsQ3Question;

  /// No description provided for @helpCenterNoMailAppSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Aucune app mail configurée. Écris-nous à {supportEmail}.'**
  String helpCenterNoMailAppSnackbar(String supportEmail);

  /// No description provided for @helpCenterNotFoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Écris-nous, on te répond directement.'**
  String get helpCenterNotFoundSubtitle;

  /// No description provided for @helpCenterNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu n’as pas trouvé ta réponse ?'**
  String get helpCenterNotFoundTitle;

  /// No description provided for @helpCenterRemindersQ1Answer.
  ///
  /// In fr, this message translates to:
  /// **'Va dans Profil > Notifications. Active l’interrupteur du repas souhaité (petit-déjeuner, déjeuner, dîner) et choisis l’heure du rappel en appuyant sur l’horaire affiché.'**
  String get helpCenterRemindersQ1Answer;

  /// No description provided for @helpCenterRemindersQ1Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment activer les rappels de repas ?'**
  String get helpCenterRemindersQ1Question;

  /// No description provided for @helpCenterRemindersQ2Answer.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie que les notifications sont autorisées pour l’app dans les réglages de ton téléphone. Sur certains téléphones Android, il faut aussi désactiver l’optimisation de batterie pour l’app afin que les rappels sonnent à l’heure prévue.'**
  String get helpCenterRemindersQ2Answer;

  /// No description provided for @helpCenterRemindersQ2Question.
  ///
  /// In fr, this message translates to:
  /// **'Je n’ai reçu aucune notification, que faire ?'**
  String get helpCenterRemindersQ2Question;

  /// No description provided for @helpCenterSectionAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte & abonnement'**
  String get helpCenterSectionAccountTitle;

  /// No description provided for @helpCenterSectionCoachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coach IA & idées de repas'**
  String get helpCenterSectionCoachTitle;

  /// No description provided for @helpCenterSectionMealsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Repas & analyse IA'**
  String get helpCenterSectionMealsTitle;

  /// No description provided for @helpCenterSectionRemindersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels & notifications'**
  String get helpCenterSectionRemindersTitle;

  /// No description provided for @localAiSettingsCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get localAiSettingsCancelButton;

  /// No description provided for @localAiSettingsDeleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get localAiSettingsDeleteButton;

  /// No description provided for @localAiSettingsDeleteDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle sera supprimé de ton téléphone. Les fonctionnalités IA repasseront en mode cloud.'**
  String get localAiSettingsDeleteDialogBody;

  /// No description provided for @localAiSettingsDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le modèle IA'**
  String get localAiSettingsDeleteDialogTitle;

  /// No description provided for @localAiSettingsDeleteModelButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le modèle'**
  String get localAiSettingsDeleteModelButton;

  /// No description provided for @localAiSettingsDownloadButton.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get localAiSettingsDownloadButton;

  /// No description provided for @localAiSettingsDownloadDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle pèse environ {size}. Nous recommandons une connexion Wi-Fi pour ce téléchargement.'**
  String localAiSettingsDownloadDialogBody(String size);

  /// No description provided for @localAiSettingsDownloadDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le modèle IA'**
  String get localAiSettingsDownloadDialogTitle;

  /// No description provided for @localAiSettingsDownloadFailedError.
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement : {error}'**
  String localAiSettingsDownloadFailedError(String error);

  /// No description provided for @localAiSettingsDownloadProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'{percent}%'**
  String localAiSettingsDownloadProgressLabel(String percent);

  /// No description provided for @localAiSettingsEnableLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'IA locale'**
  String get localAiSettingsEnableLabel;

  /// No description provided for @localAiSettingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Traite tes photos de repas et tes messages du coach directement sur ton téléphone, sans connexion, et sans utiliser le quota IA partagé de l\'app. Fonctionnalité optionnelle : sans elle, tout continue de fonctionner via le cloud comme aujourd\'hui.'**
  String get localAiSettingsIntro;

  /// No description provided for @localAiSettingsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les réglages IA locale.'**
  String get localAiSettingsLoadError;

  /// No description provided for @localAiSettingsModelDownloadedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle téléchargé'**
  String get localAiSettingsModelDownloadedLabel;

  /// No description provided for @localAiSettingsModelNotDownloadedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle non téléchargé'**
  String get localAiSettingsModelNotDownloadedLabel;

  /// No description provided for @localAiSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'IA locale'**
  String get localAiSettingsTitle;

  /// No description provided for @loginContinueWithDiscord.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Discord'**
  String get loginContinueWithDiscord;

  /// No description provided for @loginDividerOrContinueWith.
  ///
  /// In fr, this message translates to:
  /// **'OU CONTINUER AVEC'**
  String get loginDividerOrContinueWith;

  /// No description provided for @loginEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.fr'**
  String get loginEmailHint;

  /// No description provided for @loginEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginErrorFillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs.'**
  String get loginErrorFillAllFields;

  /// No description provided for @loginForgotPasswordLink.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get loginForgotPasswordLink;

  /// No description provided for @loginHeaderLabel.
  ///
  /// In fr, this message translates to:
  /// **'CONNEXION'**
  String get loginHeaderLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignupPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? S\'inscrire'**
  String get loginSignupPrompt;

  /// No description provided for @loginSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmitButton;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour suivre vos objectifs'**
  String get loginSubtitle;

  /// No description provided for @loginWelcomeBackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ravi de vous revoir'**
  String get loginWelcomeBackTitle;

  /// No description provided for @mealAnalysisAddIngredientButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ingrédient'**
  String get mealAnalysisAddIngredientButton;

  /// No description provided for @mealAnalysisAddIngredientSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ingrédient'**
  String get mealAnalysisAddIngredientSheetTitle;

  /// No description provided for @mealAnalysisAddIngredientSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne les valeurs pour la portion que tu ajoutes.'**
  String get mealAnalysisAddIngredientSubtitle;

  /// No description provided for @mealAnalysisBadgeAi.
  ///
  /// In fr, this message translates to:
  /// **'Identifié par l\'IA'**
  String get mealAnalysisBadgeAi;

  /// No description provided for @mealAnalysisBadgeBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Trouvé via code-barres'**
  String get mealAnalysisBadgeBarcode;

  /// No description provided for @mealAnalysisBadgeGluc.
  ///
  /// In fr, this message translates to:
  /// **'GLUC'**
  String get mealAnalysisBadgeGluc;

  /// No description provided for @mealAnalysisBadgeLip.
  ///
  /// In fr, this message translates to:
  /// **'LIP'**
  String get mealAnalysisBadgeLip;

  /// No description provided for @mealAnalysisBadgeProt.
  ///
  /// In fr, this message translates to:
  /// **'PROT'**
  String get mealAnalysisBadgeProt;

  /// No description provided for @mealAnalysisDefaultMealName.
  ///
  /// In fr, this message translates to:
  /// **'Repas IA'**
  String get mealAnalysisDefaultMealName;

  /// No description provided for @mealAnalysisErrorCaloriesInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entre les calories de cette portion.'**
  String get mealAnalysisErrorCaloriesInvalid;

  /// No description provided for @mealAnalysisErrorNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entre le nom de l\'ingrédient.'**
  String get mealAnalysisErrorNameRequired;

  /// No description provided for @mealAnalysisErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Oups !'**
  String get mealAnalysisErrorTitle;

  /// No description provided for @mealAnalysisErrorWeightInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entre un poids valide (en g).'**
  String get mealAnalysisErrorWeightInvalid;

  /// No description provided for @mealAnalysisFieldCaloriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get mealAnalysisFieldCaloriesLabel;

  /// No description provided for @mealAnalysisFieldNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'ingrédient'**
  String get mealAnalysisFieldNameLabel;

  /// No description provided for @mealAnalysisFieldWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get mealAnalysisFieldWeightLabel;

  /// No description provided for @mealAnalysisGramsValue.
  ///
  /// In fr, this message translates to:
  /// **'{value}g'**
  String mealAnalysisGramsValue(String value);

  /// No description provided for @mealAnalysisHowItWorksBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre IA identifie les ingrédients de ton assiette et estime leurs valeurs nutritionnelles. Ajuste les quantités avec + / - si besoin, retire un ingrédient avec l’icône poubelle, puis valide pour l’enregistrer dans ton journal du jour.'**
  String get mealAnalysisHowItWorksBody;

  /// No description provided for @mealAnalysisHowItWorksConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get mealAnalysisHowItWorksConfirm;

  /// No description provided for @mealAnalysisHowItWorksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get mealAnalysisHowItWorksTitle;

  /// No description provided for @mealAnalysisIngredientsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez les quantités si nécessaire'**
  String get mealAnalysisIngredientsSubtitle;

  /// No description provided for @mealAnalysisIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get mealAnalysisIngredientsTitle;

  /// No description provided for @mealAnalysisKcalValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} kcal'**
  String mealAnalysisKcalValue(String value);

  /// No description provided for @mealAnalysisLoadingBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Recherche du produit...'**
  String get mealAnalysisLoadingBarcode;

  /// No description provided for @mealAnalysisLoadingHint.
  ///
  /// In fr, this message translates to:
  /// **'Cela prend généralement quelques secondes.'**
  String get mealAnalysisLoadingHint;

  /// No description provided for @mealAnalysisLoadingLabel.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA lit l\'étiquette du produit...'**
  String get mealAnalysisLoadingLabel;

  /// No description provided for @mealAnalysisLoadingPlate.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA analyse votre assiette...'**
  String get mealAnalysisLoadingPlate;

  /// No description provided for @mealAnalysisMacroCarbs.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get mealAnalysisMacroCarbs;

  /// No description provided for @mealAnalysisMacroFat.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get mealAnalysisMacroFat;

  /// No description provided for @mealAnalysisMacroFiber.
  ///
  /// In fr, this message translates to:
  /// **'Fibres'**
  String get mealAnalysisMacroFiber;

  /// No description provided for @mealAnalysisMacroProtein.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get mealAnalysisMacroProtein;

  /// No description provided for @mealAnalysisMacroSatFat.
  ///
  /// In fr, this message translates to:
  /// **'Sat.'**
  String get mealAnalysisMacroSatFat;

  /// No description provided for @mealAnalysisMacroSugar.
  ///
  /// In fr, this message translates to:
  /// **'Sucres'**
  String get mealAnalysisMacroSugar;

  /// No description provided for @mealAnalysisNutritionSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÉSUMÉ NUTRITIONNEL'**
  String get mealAnalysisNutritionSummaryTitle;

  /// No description provided for @mealAnalysisRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get mealAnalysisRetryButton;

  /// No description provided for @mealAnalysisSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider et sauvegarder'**
  String get mealAnalysisSaveButton;

  /// No description provided for @mealAnalysisSaveSuccessSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Repas sauvegardé avec succès !'**
  String get mealAnalysisSaveSuccessSnackbar;

  /// No description provided for @mealAnalysisSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get mealAnalysisSubmitButton;

  /// No description provided for @mealAnalysisTitleMeal.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE DU REPAS'**
  String get mealAnalysisTitleMeal;

  /// No description provided for @mealAnalysisTitleProduct.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE DU PRODUIT'**
  String get mealAnalysisTitleProduct;

  /// No description provided for @mealAnalysisTotalKcalLabel.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL KCAL'**
  String get mealAnalysisTotalKcalLabel;

  /// No description provided for @mealAnalysisUnitGrams.
  ///
  /// In fr, this message translates to:
  /// **'g'**
  String get mealAnalysisUnitGrams;

  /// No description provided for @mealAnalysisUnitKcal.
  ///
  /// In fr, this message translates to:
  /// **'kcal'**
  String get mealAnalysisUnitKcal;

  /// No description provided for @mealAnalysisWeightValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} G'**
  String mealAnalysisWeightValue(String value);

  /// No description provided for @mealSuggestionCardGlucLabel.
  ///
  /// In fr, this message translates to:
  /// **'GLUC'**
  String get mealSuggestionCardGlucLabel;

  /// No description provided for @mealSuggestionCardGramsValue.
  ///
  /// In fr, this message translates to:
  /// **'{value}g'**
  String mealSuggestionCardGramsValue(String value);

  /// No description provided for @mealSuggestionCardKcalLabel.
  ///
  /// In fr, this message translates to:
  /// **'{kcal} kcal'**
  String mealSuggestionCardKcalLabel(String kcal);

  /// No description provided for @mealSuggestionCardLipLabel.
  ///
  /// In fr, this message translates to:
  /// **'LIP'**
  String get mealSuggestionCardLipLabel;

  /// No description provided for @mealSuggestionCardProtLabel.
  ///
  /// In fr, this message translates to:
  /// **'PROT'**
  String get mealSuggestionCardProtLabel;

  /// No description provided for @mealSuggestionsAdjustPresetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ajuste ce repas pour mon objectif: {title}'**
  String mealSuggestionsAdjustPresetMessage(String title);

  /// No description provided for @mealSuggestionsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune idée de repas disponible pour le moment.'**
  String get mealSuggestionsEmptyMessage;

  /// No description provided for @mealSuggestionsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer des idées de repas pour le moment.'**
  String get mealSuggestionsLoadError;

  /// No description provided for @mealSuggestionsRegenerateTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get mealSuggestionsRegenerateTooltip;

  /// No description provided for @mealSuggestionsRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get mealSuggestionsRetryButton;

  /// No description provided for @mealSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Idées repas'**
  String get mealSuggestionsTitle;

  /// No description provided for @notificationSettingsAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get notificationSettingsAddButton;

  /// No description provided for @notificationSettingsAddSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get notificationSettingsAddSubmitButton;

  /// No description provided for @notificationSettingsCustomRemindersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes rappels personnalisés.'**
  String get notificationSettingsCustomRemindersLoadError;

  /// No description provided for @notificationSettingsCustomRemindersTitle.
  ///
  /// In fr, this message translates to:
  /// **'RAPPELS PERSONNALISÉS'**
  String get notificationSettingsCustomRemindersTitle;

  /// No description provided for @notificationSettingsDisabledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get notificationSettingsDisabledLabel;

  /// No description provided for @notificationSettingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Reçois un rappel pour penser à logguer chacun de tes repas.'**
  String get notificationSettingsIntro;

  /// No description provided for @notificationSettingsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les réglages de notifications.'**
  String get notificationSettingsLoadError;

  /// No description provided for @notificationSettingsNameRequiredError.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à ton rappel.'**
  String get notificationSettingsNameRequiredError;

  /// No description provided for @notificationSettingsNewReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau rappel'**
  String get notificationSettingsNewReminderTitle;

  /// No description provided for @notificationSettingsNoCustomReminders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel personnalisé pour l\'instant.'**
  String get notificationSettingsNoCustomReminders;

  /// No description provided for @notificationSettingsReminderAtLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rappel à {time}'**
  String notificationSettingsReminderAtLabel(String time);

  /// No description provided for @notificationSettingsReminderNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Collation, Boire de l\'eau...'**
  String get notificationSettingsReminderNameHint;

  /// No description provided for @notificationSettingsReminderNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du rappel'**
  String get notificationSettingsReminderNameLabel;

  /// No description provided for @notificationSettingsTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure : {time}'**
  String notificationSettingsTimeLabel(String time);

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSlotBreakfast.
  ///
  /// In fr, this message translates to:
  /// **'Petit-déjeuner'**
  String get notificationSettingsSlotBreakfast;

  /// No description provided for @notificationSettingsSlotLunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get notificationSettingsSlotLunch;

  /// No description provided for @notificationSettingsSlotDinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get notificationSettingsSlotDinner;

  /// No description provided for @notificationSettingsBodyBreakfast.
  ///
  /// In fr, this message translates to:
  /// **'Pense à prendre en photo ton petit-déjeuner pour le logguer !'**
  String get notificationSettingsBodyBreakfast;

  /// No description provided for @notificationSettingsBodyLunch.
  ///
  /// In fr, this message translates to:
  /// **'Pense à prendre en photo ton déjeuner pour le logguer !'**
  String get notificationSettingsBodyLunch;

  /// No description provided for @notificationSettingsBodyDinner.
  ///
  /// In fr, this message translates to:
  /// **'Pense à prendre en photo ton dîner pour le logguer !'**
  String get notificationSettingsBodyDinner;

  /// No description provided for @nutritionTrends30DaySectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tendance calories · 30 derniers jours'**
  String get nutritionTrends30DaySectionTitle;

  /// No description provided for @nutritionTrendsCaloriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get nutritionTrendsCaloriesLabel;

  /// No description provided for @nutritionTrendsCaloriesSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calories · 7 derniers jours'**
  String get nutritionTrendsCaloriesSectionTitle;

  /// No description provided for @nutritionTrendsCarbsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get nutritionTrendsCarbsLabel;

  /// No description provided for @nutritionTrendsDailyAveragesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Moyennes quotidiennes'**
  String get nutritionTrendsDailyAveragesTitle;

  /// No description provided for @nutritionTrendsDayFri.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get nutritionTrendsDayFri;

  /// No description provided for @nutritionTrendsDayMon.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get nutritionTrendsDayMon;

  /// No description provided for @nutritionTrendsDaySat.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get nutritionTrendsDaySat;

  /// No description provided for @nutritionTrendsDaySun.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get nutritionTrendsDaySun;

  /// No description provided for @nutritionTrendsDayThu.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get nutritionTrendsDayThu;

  /// No description provided for @nutritionTrendsDayTue.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get nutritionTrendsDayTue;

  /// No description provided for @nutritionTrendsDayWed.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get nutritionTrendsDayWed;

  /// No description provided for @nutritionTrendsEmptyState.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez de repas enregistrés cette semaine pour afficher des tendances.'**
  String get nutritionTrendsEmptyState;

  /// No description provided for @nutritionTrendsErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String nutritionTrendsErrorMessage(String error);

  /// No description provided for @nutritionTrendsExtraNutrientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autres nutriments (moyenne/jour)'**
  String get nutritionTrendsExtraNutrientsTitle;

  /// No description provided for @nutritionTrendsFatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get nutritionTrendsFatLabel;

  /// No description provided for @nutritionTrendsFiberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fibres'**
  String get nutritionTrendsFiberLabel;

  /// No description provided for @nutritionTrendsGoProButton.
  ///
  /// In fr, this message translates to:
  /// **'Passer PRO'**
  String get nutritionTrendsGoProButton;

  /// No description provided for @nutritionTrendsMacroDistributionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des macros (moyenne)'**
  String get nutritionTrendsMacroDistributionTitle;

  /// No description provided for @nutritionTrendsProLockedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Débloque les macros détaillées et les tendances nutritionnelles sur 7 jours.'**
  String get nutritionTrendsProLockedDescription;

  /// No description provided for @nutritionTrendsProLockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux membres PRO'**
  String get nutritionTrendsProLockedTitle;

  /// No description provided for @nutritionTrendsProteinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get nutritionTrendsProteinLabel;

  /// No description provided for @nutritionTrendsSatFatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Graisses sat.'**
  String get nutritionTrendsSatFatLabel;

  /// No description provided for @nutritionTrendsSugarLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sucres'**
  String get nutritionTrendsSugarLabel;

  /// No description provided for @nutritionTrendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyses avancées'**
  String get nutritionTrendsTitle;

  /// No description provided for @onboardingAgeSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre Âge'**
  String get onboardingAgeSectionLabel;

  /// No description provided for @onboardingAgeUnitSuffix.
  ///
  /// In fr, this message translates to:
  /// **'ans'**
  String get onboardingAgeUnitSuffix;

  /// No description provided for @onboardingErrorGoalRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton objectif principal.'**
  String get onboardingErrorGoalRequired;

  /// No description provided for @onboardingErrorInvalidAge.
  ///
  /// In fr, this message translates to:
  /// **'Entre un âge valide.'**
  String get onboardingErrorInvalidAge;

  /// No description provided for @onboardingErrorInvalidHeight.
  ///
  /// In fr, this message translates to:
  /// **'Entre ta taille en cm.'**
  String get onboardingErrorInvalidHeight;

  /// No description provided for @onboardingErrorInvalidWeight.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton poids.'**
  String get onboardingErrorInvalidWeight;

  /// No description provided for @onboardingErrorSaveProfile.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer le profil : {error}'**
  String onboardingErrorSaveProfile(String error);

  /// No description provided for @onboardingErrorSexRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton sexe pour continuer.'**
  String get onboardingErrorSexRequired;

  /// No description provided for @onboardingGoalGainMuscle.
  ///
  /// In fr, this message translates to:
  /// **'Prendre de la masse'**
  String get onboardingGoalGainMuscle;

  /// No description provided for @onboardingGoalGainMuscleDescription.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter l\'apport pour prendre du muscle.'**
  String get onboardingGoalGainMuscleDescription;

  /// No description provided for @onboardingGoalLoseWeight.
  ///
  /// In fr, this message translates to:
  /// **'Perdre du poids'**
  String get onboardingGoalLoseWeight;

  /// No description provided for @onboardingGoalLoseWeightDescription.
  ///
  /// In fr, this message translates to:
  /// **'Réduire l\'apport calorique et brûler les graisses.'**
  String get onboardingGoalLoseWeightDescription;

  /// No description provided for @onboardingGoalMaintain.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir mon poids'**
  String get onboardingGoalMaintain;

  /// No description provided for @onboardingGoalMaintainDescription.
  ///
  /// In fr, this message translates to:
  /// **'Équilibrer les macros pour une santé stable.'**
  String get onboardingGoalMaintainDescription;

  /// No description provided for @onboardingGoalSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre objectif ?'**
  String get onboardingGoalSectionLabel;

  /// No description provided for @onboardingHeightSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre Taille'**
  String get onboardingHeightSectionLabel;

  /// No description provided for @onboardingSexFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get onboardingSexFemale;

  /// No description provided for @onboardingSexMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get onboardingSexMale;

  /// No description provided for @onboardingSexOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get onboardingSexOther;

  /// No description provided for @onboardingSexSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes...'**
  String get onboardingSexSectionLabel;

  /// No description provided for @onboardingStepIndicator.
  ///
  /// In fr, this message translates to:
  /// **'Étape 1 sur 2'**
  String get onboardingStepIndicator;

  /// No description provided for @onboardingSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Calculer mon plan'**
  String get onboardingSubmitButton;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations permettent à notre IA de calculer votre besoin calorique précis.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apprenons à nous connaître'**
  String get onboardingTitle;

  /// No description provided for @onboardingWeightSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre Poids'**
  String get onboardingWeightSectionLabel;

  /// No description provided for @paywallBadgePopular.
  ///
  /// In fr, this message translates to:
  /// **'POPULAIRE'**
  String get paywallBadgePopular;

  /// No description provided for @paywallBenefitAdsFreeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une expérience fluide, premium et concentrée.'**
  String get paywallBenefitAdsFreeSubtitle;

  /// No description provided for @paywallBenefitAdsFreeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sans publicité'**
  String get paywallBenefitAdsFreeTitle;

  /// No description provided for @paywallBenefitAnalyticsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Macros détaillées et tendances nutritionnelles.'**
  String get paywallBenefitAnalyticsSubtitle;

  /// No description provided for @paywallBenefitAnalyticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyses avancées'**
  String get paywallBenefitAnalyticsTitle;

  /// No description provided for @paywallBenefitCoachSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez des recommandations adaptées à votre objectif.'**
  String get paywallBenefitCoachSubtitle;

  /// No description provided for @paywallBenefitCoachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coach de repas personnel'**
  String get paywallBenefitCoachTitle;

  /// No description provided for @paywallBenefitPhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Analysez autant de repas que nécessaire, sans limite.'**
  String get paywallBenefitPhotoSubtitle;

  /// No description provided for @paywallBenefitPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance Photo Illimitée'**
  String get paywallBenefitPhotoTitle;

  /// No description provided for @paywallChooseForfaitLabel.
  ///
  /// In fr, this message translates to:
  /// **'CHOISISSEZ VOTRE FORFAIT'**
  String get paywallChooseForfaitLabel;

  /// No description provided for @paywallDemoModeNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo : les achats sont simulés, aucun paiement réel n\'est effectué.'**
  String get paywallDemoModeNotice;

  /// No description provided for @paywallHeaderBadge.
  ///
  /// In fr, this message translates to:
  /// **'AI-HEALTH-CHEF PRO'**
  String get paywallHeaderBadge;

  /// No description provided for @paywallPeriodMonth.
  ///
  /// In fr, this message translates to:
  /// **'/ mois'**
  String get paywallPeriodMonth;

  /// No description provided for @paywallPeriodWeek.
  ///
  /// In fr, this message translates to:
  /// **'/ semaine'**
  String get paywallPeriodWeek;

  /// No description provided for @paywallPeriodYear.
  ///
  /// In fr, this message translates to:
  /// **'/ an'**
  String get paywallPeriodYear;

  /// No description provided for @paywallPlanAnnualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get paywallPlanAnnualTitle;

  /// No description provided for @paywallPlanLifetimeTitle.
  ///
  /// In fr, this message translates to:
  /// **'À vie'**
  String get paywallPlanLifetimeTitle;

  /// No description provided for @paywallPlanMonthlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get paywallPlanMonthlyTitle;

  /// No description provided for @paywallPlanWeeklyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get paywallPlanWeeklyTitle;

  /// No description provided for @paywallPreviewConfigPending.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu — configuration RevenueCat en attente'**
  String get paywallPreviewConfigPending;

  /// No description provided for @paywallPreviewDemoMode.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu — achat simulé en mode démo'**
  String get paywallPreviewDemoMode;

  /// No description provided for @paywallRestoreButton.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get paywallRestoreButton;

  /// No description provided for @paywallRestoreError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de restaurer les achats : {error}'**
  String paywallRestoreError(String error);

  /// No description provided for @paywallRestoreNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat actif trouvé pour ce compte.'**
  String get paywallRestoreNone;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Achat restauré, ton accès PRO est actif.'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallSelectionSummary.
  ///
  /// In fr, this message translates to:
  /// **'Sélection : {title} • {price} {period}'**
  String paywallSelectionSummary(String title, String price, String period);

  /// No description provided for @paywallSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Libérez tout le potentiel de votre nutrition avec l\'intelligence artificielle de pointe.'**
  String get paywallSubtitle;

  /// No description provided for @paywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez au niveau supérieur'**
  String get paywallTitle;

  /// No description provided for @paywallUnlockButton.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer AI Health Chef PRO'**
  String get paywallUnlockButton;

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Version et informations'**
  String get profileAboutSubtitle;

  /// No description provided for @profileAboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAboutTitle;

  /// No description provided for @profileAccountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profileAccountSubtitle;

  /// No description provided for @profileAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileAccountTitle;

  /// No description provided for @profileActiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get profileActiveBadge;

  /// No description provided for @profileAdvancedAnalyticsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Macros détaillées et tendances nutritionnelles'**
  String get profileAdvancedAnalyticsSubtitle;

  /// No description provided for @profileAdvancedAnalyticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyses avancées'**
  String get profileAdvancedAnalyticsTitle;

  /// No description provided for @profileAgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get profileAgeLabel;

  /// No description provided for @profileAgeValue.
  ///
  /// In fr, this message translates to:
  /// **'{age} ans'**
  String profileAgeValue(int age);

  /// No description provided for @profileCoachSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton : {tone}'**
  String profileCoachSubtitle(String tone);

  /// No description provided for @profileCoachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coach IA'**
  String get profileCoachTitle;

  /// No description provided for @profileCurrentWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids actuel'**
  String get profileCurrentWeightLabel;

  /// No description provided for @profileDefaultUserName.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get profileDefaultUserName;

  /// No description provided for @profileDietaryPrefsSubtitleWithAllergies.
  ///
  /// In fr, this message translates to:
  /// **'{dietType} · {count} allergie(s)'**
  String profileDietaryPrefsSubtitleWithAllergies(String dietType, int count);

  /// No description provided for @profileDietaryPrefsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences alimentaires'**
  String get profileDietaryPrefsTitle;

  /// No description provided for @profileGoalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get profileGoalLabel;

  /// No description provided for @profileGoalsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Calories et macros'**
  String get profileGoalsSubtitle;

  /// No description provided for @profileGoalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes objectifs'**
  String get profileGoalsTitle;

  /// No description provided for @profileHelpCenterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'FAQ, guides et tutoriels'**
  String get profileHelpCenterSubtitle;

  /// No description provided for @profileHelpCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d’aide'**
  String get profileHelpCenterTitle;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLanguageTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le profil : {error}'**
  String profileLoadError(String error);

  /// No description provided for @profileLocalAiSubtitleDefault.
  ///
  /// In fr, this message translates to:
  /// **'Scan et chat sur l\'appareil'**
  String get profileLocalAiSubtitleDefault;

  /// No description provided for @profileLocalAiSubtitleDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get profileLocalAiSubtitleDisabled;

  /// No description provided for @profileLocalAiSubtitleEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Activée'**
  String get profileLocalAiSubtitleEnabled;

  /// No description provided for @profileLocalAiSubtitleEnabledNotDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Activée · à télécharger'**
  String get profileLocalAiSubtitleEnabledNotDownloaded;

  /// No description provided for @profileLocalAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'IA locale'**
  String get profileLocalAiTitle;

  /// No description provided for @profileLogoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileLogoutButton;

  /// No description provided for @profileLogoutError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la déconnexion : {error}'**
  String profileLogoutError(String error);

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels repas et suivi'**
  String get profileNotificationsSubtitle;

  /// No description provided for @profileNotificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsTitle;

  /// No description provided for @profileProBadge.
  ///
  /// In fr, this message translates to:
  /// **'PRO'**
  String get profileProBadge;

  /// No description provided for @profileProBadgeHeader.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get profileProBadgeHeader;

  /// No description provided for @profileSectionGeneral.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRAL'**
  String get profileSectionGeneral;

  /// No description provided for @profileSectionPersonalization.
  ///
  /// In fr, this message translates to:
  /// **'PERSONNALISATION'**
  String get profileSectionPersonalization;

  /// No description provided for @profileSectionSupport.
  ///
  /// In fr, this message translates to:
  /// **'ASSISTANCE'**
  String get profileSectionSupport;

  /// No description provided for @profileSecurityComingSoonMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les réglages de sécurité et confidentialité arrivent bientôt.'**
  String get profileSecurityComingSoonMessage;

  /// No description provided for @profileSecuritySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Données et sécurité'**
  String get profileSecuritySubtitle;

  /// No description provided for @profileSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité et Confidentialité'**
  String get profileSecurityTitle;

  /// No description provided for @profileSubscriptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan PRO et facturation'**
  String get profileSubscriptionSubtitle;

  /// No description provided for @profileSubscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get profileSubscriptionTitle;

  /// No description provided for @profileTargetWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids cible'**
  String get profileTargetWeightLabel;

  /// No description provided for @profileTermsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'CGU et mentions légales'**
  String get profileTermsSubtitle;

  /// No description provided for @profileTermsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get profileTermsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'MON PROFIL'**
  String get profileTitle;

  /// No description provided for @profileUnknownUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur inconnu'**
  String get profileUnknownUser;

  /// No description provided for @profileVersionText.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef v1.0.0'**
  String get profileVersionText;

  /// No description provided for @profileWeightValue.
  ///
  /// In fr, this message translates to:
  /// **'{weight} kg'**
  String profileWeightValue(String weight);

  /// No description provided for @signupAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Déjà membre ?'**
  String get signupAlreadyMember;

  /// No description provided for @signupDividerOrSignUpWith.
  ///
  /// In fr, this message translates to:
  /// **'OU S\'INSCRIRE AVEC'**
  String get signupDividerOrSignUpWith;

  /// No description provided for @signupEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'jean.dupont@exemple.fr'**
  String get signupEmailHint;

  /// No description provided for @signupEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'ADRESSE E-MAIL'**
  String get signupEmailLabel;

  /// No description provided for @signupErrorAcceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter les conditions d\'utilisation.'**
  String get signupErrorAcceptTerms;

  /// No description provided for @signupErrorFillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs.'**
  String get signupErrorFillAllFields;

  /// No description provided for @signupFullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jean Dupont'**
  String get signupFullNameHint;

  /// No description provided for @signupFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOM COMPLET'**
  String get signupFullNameLabel;

  /// No description provided for @signupHeaderLabel.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN COMPTE'**
  String get signupHeaderLabel;

  /// No description provided for @signupLoginLink.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signupLoginLink;

  /// No description provided for @signupPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE'**
  String get signupPasswordLabel;

  /// No description provided for @signupSecureDataNotice.
  ///
  /// In fr, this message translates to:
  /// **'données cryptées & sécurisées'**
  String get signupSecureDataNotice;

  /// No description provided for @signupSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signupSubmitButton;

  /// No description provided for @signupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez-nous pour transformer votre nutrition avec intelligence artificielle.'**
  String get signupSubtitle;

  /// No description provided for @signupSuccessCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé ! Vérifiez vos emails pour confirmer.'**
  String get signupSuccessCheckEmail;

  /// No description provided for @signupTermsAcceptance.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité'**
  String get signupTermsAcceptance;

  /// No description provided for @termsAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get termsAppBarTitle;

  /// No description provided for @termsDraftBanner.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon : ce document décrit honnêtement le service, mais n’a pas encore été relu par un professionnel du droit et l’identité légale de l’éditeur reste à compléter. À finaliser avant toute publication publique de l’app.'**
  String get termsDraftBanner;

  /// No description provided for @termsLastUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : {date}'**
  String termsLastUpdated(String date);

  /// No description provided for @termsSection10Body.
  ///
  /// In fr, this message translates to:
  /// **'L’Application est fournie « en l’état ». L’éditeur ne garantit pas l’exactitude, la disponibilité continue ou l’absence d’erreur du service, notamment des estimations générées par IA. L’usage de l’Application se fait sous ta seule responsabilité.'**
  String get termsSection10Body;

  /// No description provided for @termsSection10Title.
  ///
  /// In fr, this message translates to:
  /// **'10. Responsabilité'**
  String get termsSection10Title;

  /// No description provided for @termsSection11Body.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux cesser d’utiliser l’Application et demander la suppression de ton compte à tout moment en écrivant à {supportEmail}. L’éditeur peut suspendre ou supprimer un compte en cas d’usage abusif ou de non-respect des présentes CGU.'**
  String termsSection11Body(String supportEmail);

  /// No description provided for @termsSection11Title.
  ///
  /// In fr, this message translates to:
  /// **'11. Résiliation'**
  String get termsSection11Title;

  /// No description provided for @termsSection12Body.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes CGU peuvent évoluer, notamment en fonction des fonctionnalités ajoutées à l’Application. La version en vigueur est toujours celle consultable dans l’Application.'**
  String get termsSection12Body;

  /// No description provided for @termsSection12Title.
  ///
  /// In fr, this message translates to:
  /// **'12. Modification des CGU'**
  String get termsSection12Title;

  /// No description provided for @termsSection13Body.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes CGU sont soumises au droit français.'**
  String get termsSection13Body;

  /// No description provided for @termsSection13Title.
  ///
  /// In fr, this message translates to:
  /// **'13. Droit applicable'**
  String get termsSection13Title;

  /// No description provided for @termsSection14Body.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question relative à ces CGU ou à tes données : {supportEmail}.'**
  String termsSection14Body(String supportEmail);

  /// No description provided for @termsSection14Title.
  ///
  /// In fr, this message translates to:
  /// **'14. Contact'**
  String get termsSection14Title;

  /// No description provided for @termsSection1Body.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur : [Nom de l’éditeur à compléter] — projet actuellement développé à titre personnel, sans société immatriculée à ce jour.\nContact : {supportEmail}\nHébergement des données et du backend : Supabase Inc. (infrastructure cloud tierce). Application distribuée via l’App Store (Apple) et le Google Play Store.'**
  String termsSection1Body(String supportEmail);

  /// No description provided for @termsSection1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Mentions légales'**
  String get termsSection1Title;

  /// No description provided for @termsSection2Body.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes Conditions d’Utilisation (« CGU ») régissent l’accès et l’usage de l’application mobile AI Health Chef (« l’Application »). En créant un compte ou en utilisant l’Application, tu acceptes l’intégralité des présentes CGU.'**
  String get termsSection2Body;

  /// No description provided for @termsSection2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Objet'**
  String get termsSection2Title;

  /// No description provided for @termsSection3Body.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef permet de : suivre ses repas et ses macronutriments au quotidien ; analyser une photo de repas via intelligence artificielle pour estimer les ingrédients et valeurs nutritionnelles ; échanger avec un coach nutritionnel conversationnel basé sur l’IA ; recevoir des idées de repas personnalisées ; configurer des rappels de repas ; et, via un abonnement PRO optionnel, débloquer des fonctionnalités additionnelles.'**
  String get termsSection3Body;

  /// No description provided for @termsSection3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Description du service'**
  String get termsSection3Title;

  /// No description provided for @termsSection4Body.
  ///
  /// In fr, this message translates to:
  /// **'AI Health Chef fournit des informations et estimations à titre purement informatif et ne constitue en aucun cas un avis médical, un diagnostic ou une prescription. Les calculs de calories, macros et objectifs nutritionnels sont des estimations générales. Consulte un médecin ou un·e diététicien·ne avant tout changement alimentaire significatif, en particulier en cas de pathologie, de grossesse, ou de trouble du comportement alimentaire. L’Application ne doit pas être utilisée comme seul outil de suivi dans un contexte médical.'**
  String get termsSection4Body;

  /// No description provided for @termsSection4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Ce n’est pas un avis médical'**
  String get termsSection4Title;

  /// No description provided for @termsSection5Body.
  ///
  /// In fr, this message translates to:
  /// **'Les ingrédients détectés sur photo, les valeurs nutritionnelles estimées, les réponses du coach IA et les idées de repas sont générés par des modèles d’IA tiers (actuellement Google Gemini) et peuvent contenir des erreurs, imprécisions ou approximations. Vérifie et ajuste les informations avant de t’y fier, en particulier en cas d’allergie ou de restriction alimentaire.'**
  String get termsSection5Body;

  /// No description provided for @termsSection5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Contenu généré par intelligence artificielle'**
  String get termsSection5Title;

  /// No description provided for @termsSection6Body.
  ///
  /// In fr, this message translates to:
  /// **'L’utilisation de l’Application nécessite la création d’un compte. Tu es responsable de l’exactitude des informations fournies et de la confidentialité de tes identifiants de connexion. Toute activité réalisée depuis ton compte est présumée effectuée par toi.'**
  String get termsSection6Body;

  /// No description provided for @termsSection6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Compte utilisateur'**
  String get termsSection6Title;

  /// No description provided for @termsSection7Body.
  ///
  /// In fr, this message translates to:
  /// **'Certaines fonctionnalités sont réservées aux utilisateurs abonnés (« PRO »). L’achat, le renouvellement automatique et l’annulation de l’abonnement sont intégralement gérés par la plateforme de paiement de ton appareil (App Store ou Google Play), pas directement par l’éditeur. L’abonnement se renouvelle automatiquement sauf annulation au moins 24h avant la fin de la période en cours, depuis les réglages de ton compte Apple ou Google. Les demandes de remboursement relèvent des politiques d’Apple/Google, pas de l’éditeur.'**
  String get termsSection7Body;

  /// No description provided for @termsSection7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Abonnement PRO'**
  String get termsSection7Title;

  /// No description provided for @termsSection8Body.
  ///
  /// In fr, this message translates to:
  /// **'L’Application traite notamment : ton email et ton mot de passe (authentification) ; des données de profil santé (sexe, âge, poids, taille, objectif) ; les photos de repas que tu prends et les données nutritionnelles associées ; ta photo de profil ; et l’historique de tes échanges avec le coach IA. Ces données sont utilisées uniquement pour fournir le service (calcul de tes objectifs, analyse de tes repas, suivi de ton historique) et sont hébergées par Supabase. Les photos de repas sont transmises à Google (modèle Gemini) le temps de l’analyse. Aucune donnée n’est vendue à des tiers. Tu peux demander l’accès, la rectification ou la suppression de tes données à tout moment en écrivant à {supportEmail}.'**
  String termsSection8Body(String supportEmail);

  /// No description provided for @termsSection8Title.
  ///
  /// In fr, this message translates to:
  /// **'8. Données personnelles'**
  String get termsSection8Title;

  /// No description provided for @termsSection9Body.
  ///
  /// In fr, this message translates to:
  /// **'Le nom, le logo et les éléments graphiques de l’Application appartiennent à l’éditeur. Le contenu que tu crées (photos, messages) reste ta propriété ; tu accordes à l’éditeur le droit de le traiter uniquement dans le cadre du fonctionnement du service (ex. envoi à un fournisseur d’IA pour analyse).'**
  String get termsSection9Body;

  /// No description provided for @termsSection9Title.
  ///
  /// In fr, this message translates to:
  /// **'9. Propriété intellectuelle'**
  String get termsSection9Title;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
