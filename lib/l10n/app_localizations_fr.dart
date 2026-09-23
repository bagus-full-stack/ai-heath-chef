// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AI Health Chef';

  @override
  String get bmiCategoryUnderweight => 'Insuffisance pondérale';

  @override
  String get bmiCategoryNormal => 'Corpulence normale';

  @override
  String get bmiCategoryOverweight => 'Surpoids';

  @override
  String get bmiCategoryObese => 'Obésité';

  @override
  String get aboutAppBarTitle => 'À propos';

  @override
  String get aboutAppName => 'AI Health Chef';

  @override
  String get aboutContactLinkTitle => 'Contacter le support';

  @override
  String aboutCopyright(int year) {
    return '© $year AI Health Chef';
  }

  @override
  String get aboutDescription =>
      'AI Health Chef t’aide à suivre tes repas et tes objectifs nutritionnels : scanne ton assiette pour une estimation automatique des calories et macros, échange avec un coach IA, reçois des idées de repas personnalisées et des rappels pour ne rien oublier.';

  @override
  String get aboutHelpCenterLinkTitle => 'Centre d’aide';

  @override
  String get aboutMailtoSubject => 'Contact AI Health Chef';

  @override
  String aboutNoMailAppSnackbar(String supportEmail) {
    return 'Aucune app mail configurée. Écris-nous à $supportEmail.';
  }

  @override
  String get aboutTermsLinkTitle => 'Conditions d’utilisation';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get aboutVersionLoading => '…';

  @override
  String get accountAgeLabel => 'Âge';

  @override
  String get accountAgeSuffix => 'ans';

  @override
  String accountBmiLabel(String label) {
    return 'IMC : $label';
  }

  @override
  String get accountBmiPlaceholder =>
      'Renseigne ton poids et ta taille pour voir ton IMC.';

  @override
  String accountBmiRangeLabel(String label, String range) {
    return 'Plage $label : $range';
  }

  @override
  String get accountChooseFromGallery => 'Choisir dans la galerie';

  @override
  String get accountCurrentWeightLabel => 'Poids actuel';

  @override
  String get accountErrorInvalidAge => 'Entre un âge valide.';

  @override
  String get accountErrorInvalidCurrentWeight => 'Entre ton poids actuel.';

  @override
  String get accountErrorInvalidHeight => 'Entre ta taille en cm.';

  @override
  String get accountErrorInvalidTargetWeight => 'Entre un poids cible valide.';

  @override
  String get accountErrorNameEmpty => 'Ton nom ne peut pas être vide.';

  @override
  String get accountFullNameLabel => 'Nom complet';

  @override
  String get accountGoalGainMuscle => 'Prise de masse';

  @override
  String get accountGoalLoseWeight => 'Perte de poids';

  @override
  String get accountGoalMaintain => 'Maintien';

  @override
  String get accountHeightLabel => 'Taille';

  @override
  String get accountHeightSuffix => 'cm';

  @override
  String accountLoadError(String error) {
    return 'Impossible de charger le profil : $error';
  }

  @override
  String get accountMainGoalLabel => 'Objectif principal';

  @override
  String get accountSaveButton => 'Enregistrer';

  @override
  String accountSaveError(String error) {
    return 'Impossible d’enregistrer : $error';
  }

  @override
  String get accountSexFemale => 'Femme';

  @override
  String get accountSexLabel => 'Sexe';

  @override
  String get accountSexMale => 'Homme';

  @override
  String get accountSexOther => 'Autre';

  @override
  String get accountTakePhoto => 'Prendre une photo';

  @override
  String get accountTargetWeightLabel => 'Poids cible';

  @override
  String get accountTitle => 'MON COMPTE';

  @override
  String get accountUpdateSuccess => 'Profil mis à jour.';

  @override
  String get accountWeightSuffix => 'kg';

  @override
  String get barcodeScannerHintCaption => 'Cadre le code-barres du produit';

  @override
  String get barcodeScannerTitleCaption => 'SCANNER UN PRODUIT';

  @override
  String get cameraCaptureAiAnalysisCaption => 'ANALYSE NUTRITIONNELLE IA';

  @override
  String get cameraCaptureBackButton => 'Retour';

  @override
  String get cameraCaptureCameraErrorFallback =>
      'Impossible d’ouvrir la caméra.';

  @override
  String cameraCaptureCaptureFailedMessage(String error) {
    return 'Échec de la capture : $error';
  }

  @override
  String get cameraCaptureChooseGalleryPhotoButton =>
      'Choisir une photo depuis la galerie';

  @override
  String get cameraCaptureFrameMealHint => 'Cadrez votre plat au centre';

  @override
  String get cameraCaptureFrameProductHint => 'Cadrez l’étiquette du produit';

  @override
  String get cameraCaptureGalleryButton => 'GALERIE';

  @override
  String cameraCaptureGalleryOpenError(String error) {
    return 'Impossible d’ouvrir la galerie : $error';
  }

  @override
  String get cameraCaptureHelpBody =>
      'Centre ton assiette dans le cercle, garde l’appareil stable puis appuie sur le déclencheur. Notre IA analyse automatiquement les aliments et leurs valeurs nutritionnelles.';

  @override
  String get cameraCaptureHelpDismiss => 'Compris';

  @override
  String get cameraCaptureHelpTitle => 'Comment ça marche ?';

  @override
  String get cameraCaptureModeManual => 'Manuel';

  @override
  String get cameraCaptureModeMeal => 'Repas';

  @override
  String get cameraCaptureModeProduct => 'Produit';

  @override
  String get cameraCaptureModeScanner => 'Scanner';

  @override
  String get cameraCaptureNoCameraMessage =>
      'Aucune caméra disponible sur cet appareil.';

  @override
  String cameraCaptureOpenCameraError(String error) {
    return 'Impossible d’ouvrir la caméra : $error';
  }

  @override
  String get cameraCaptureRetryButton => 'Réessayer';

  @override
  String get checkoutAppBarTitle => 'Finaliser la commande';

  @override
  String checkoutConfirmButton(String price, String period) {
    return 'Confirmer • $price $period';
  }

  @override
  String get checkoutDefaultPlanTitle => 'Abonnement PRO';

  @override
  String get checkoutDemoModeNotice =>
      'Mode démo : cet achat est simulé, aucun paiement ni compte App Store / Google Play n\'est sollicité.';

  @override
  String get checkoutOrderSummaryBrand => 'AI Health Chef PRO';

  @override
  String get checkoutOrderSummaryDemoNotice =>
      'Mode démo — l\'achat sera simulé, aucun paiement réel';

  @override
  String get checkoutPaymentMethodLabel => 'MOYEN DE PAIEMENT';

  @override
  String get checkoutPendingConfirmation =>
      'Achat effectué, en attente de confirmation.';

  @override
  String get checkoutPlanLabel => 'Forfait';

  @override
  String checkoutPurchaseError(String error) {
    return 'Échec de l\'achat : $error';
  }

  @override
  String get checkoutRenewalDisclaimer =>
      'L\'abonnement se renouvelle automatiquement sauf annulation au moins 24h avant la fin de la période, depuis les réglages de ton compte App Store ou Google Play.';

  @override
  String get checkoutRenewalLabel => 'Renouvellement';

  @override
  String get checkoutRenewalValue => 'Automatique, résiliable à tout moment';

  @override
  String get checkoutSecurePaymentNotice =>
      'Paiement géré en toute sécurité par l\'App Store / Google Play. Aucune information bancaire n\'est demandée dans l\'application.';

  @override
  String get checkoutSuccessDemo =>
      'Achat simulé (mode démo)\nAccès PRO débloqué !';

  @override
  String get checkoutSuccessReal =>
      'Abonnement activé !\nBienvenue dans AI Health Chef PRO.';

  @override
  String get checkoutSummaryLabel => 'RÉCAPITULATIF';

  @override
  String get checkoutTotalLabel => 'Total';

  @override
  String coachAdjustMealPresetMessage(String mealTitle) {
    return 'Ajuste ce repas pour mon objectif: $mealTitle';
  }

  @override
  String get coachCancelButton => 'Annuler';

  @override
  String get coachCarbsLabel => 'GLUCIDES';

  @override
  String get coachDailyObjectiveTitle => 'OBJECTIF QUOTIDIEN';

  @override
  String get coachFatLabel => 'LIPIDES';

  @override
  String get coachGoalMaintainLabel => 'Maintien';

  @override
  String get coachHeaderTitle => 'COACH NUTRITION';

  @override
  String get coachInputHint => 'Écris ta question...';

  @override
  String get coachKcalUnitLabel => ' kcal';

  @override
  String get coachMealSuggestionsEmptyText =>
      'Aucune idée de repas disponible pour le moment.';

  @override
  String get coachMealSuggestionsErrorText =>
      'Impossible de générer des idées de repas pour le moment.';

  @override
  String coachNeedValueGrams(int current, int target) {
    return '$current/${target}g';
  }

  @override
  String get coachNeedsTitle => 'VOS BESOINS';

  @override
  String get coachNextMealIdeasTitle => 'Idées Prochain Repas';

  @override
  String get coachPersonalizationAppBarTitle => 'Coach IA';

  @override
  String get coachPersonalizationIntro =>
      'Choisis le ton que le Coach IA adopte dans ses réponses.';

  @override
  String get coachPersonalizationToneBienveillantDescription =>
      'Doux, rassurant, sans jugement sur tes écarts.';

  @override
  String get coachPersonalizationToneBienveillantLabel =>
      'Bienveillant & calme';

  @override
  String get coachPersonalizationToneDirectDescription =>
      'Droit au but, des conseils actionnables sans détour.';

  @override
  String get coachPersonalizationToneDirectLabel => 'Direct & concis';

  @override
  String get coachPersonalizationToneHumoristiqueDescription =>
      'Léger et avec humour, tout en restant utile.';

  @override
  String get coachPersonalizationToneHumoristiqueLabel => 'Humoristique';

  @override
  String get coachPersonalizationToneMotivantDescription =>
      'Encourageant, dynamique, te pousse à avancer.';

  @override
  String get coachPersonalizationToneMotivantLabel => 'Motivant & énergique';

  @override
  String get coachPromptFatLossLabel => 'Perte de gras';

  @override
  String get coachPromptFatLossMessage =>
      'Comment optimiser ma perte de gras aujourd\'hui ?';

  @override
  String get coachPromptIdeasLabel => 'Idées repas';

  @override
  String get coachPromptIdeasMessage =>
      'Donne-moi une idée de repas riche en protéines.';

  @override
  String get coachPromptPostWorkoutLabel => 'Après sport';

  @override
  String get coachPromptPostWorkoutMessage =>
      'Que manger après ma séance pour récupérer ?';

  @override
  String get coachProteinLabel => 'PROTÉINES';

  @override
  String get coachRealtimeBannerLabel => 'ANALYSE EN TEMPS RÉEL';

  @override
  String coachRemainingKcalText(int remainingKcal, String goalLabel) {
    return 'Il vous reste $remainingKcal kcal pour atteindre votre objectif de $goalLabel.';
  }

  @override
  String get coachResetButton => 'Réinitialiser';

  @override
  String get coachResetDialogContent =>
      'Tout l\'historique de discussion avec le coach sera supprimé.';

  @override
  String get coachResetDialogTitle => 'Réinitialiser la conversation ?';

  @override
  String get coachResetTooltip => 'Réinitialiser la conversation';

  @override
  String get coachRetryButton => 'Réessayer';

  @override
  String get coachSeeAllButton => 'Tout voir';

  @override
  String get coachSheetSubtitle => 'Pose une question sur tes repas';

  @override
  String get coachTipFatLossText =>
      'Pour optimiser votre perte de gras, privilégiez des sources de protéines maigres comme le blanc de poulet ou le tofu pour votre prochain repas.';

  @override
  String get coachTipTitle => 'Conseil du Chef IA';

  @override
  String get coachTitle => 'Coach IA';

  @override
  String get comingSoonDefaultMessage =>
      'Cette fonctionnalité arrive prochainement.';

  @override
  String get comingSoonDefaultTitle => 'Bientôt disponible';

  @override
  String dashboardBmiLabel(String label) {
    return 'IMC : $label';
  }

  @override
  String dashboardBmiRangeLabel(String label, String range) {
    return 'Plage $label : $range';
  }

  @override
  String dashboardCalorieGoalLabel(int kcal) {
    return ' Objectif: $kcal';
  }

  @override
  String get dashboardCarbsLabel => 'GLUCIDES';

  @override
  String get dashboardEmptyMealsMessage =>
      'Aucun repas enregistré aujourd\'hui. Scannez votre première assiette !';

  @override
  String get dashboardFatLabel => 'LIPIDES';

  @override
  String dashboardHydrationAddedMessage(int amount) {
    return '$amount ml ajoutés';
  }

  @override
  String dashboardHydrationGoalLabel(int current, int goal) {
    return '$current / $goal ml';
  }

  @override
  String get dashboardHydrationTitle => 'Hydratation';

  @override
  String get dashboardHydrationUndoButton => 'Annuler';

  @override
  String get dashboardKcalRemainingLabel => 'KCAL RESTANT';

  @override
  String dashboardMealCaloriesLabel(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get dashboardMealJournalTitle => 'Journal des repas';

  @override
  String dashboardMealRepeatedMessage(String name) {
    return '$name a été rajouté à aujourd\'hui.';
  }

  @override
  String dashboardMealsLoadError(String error) {
    return 'Erreur: $error';
  }

  @override
  String get dashboardProteinLabel => 'PROTÉINES';

  @override
  String get dashboardRepeatMealTooltip => 'Refaire ce repas';

  @override
  String get dashboardTodayTitle => 'Aujourd\'hui';

  @override
  String get dietaryPreferencesAllergiesDescription =>
      'Elles seront évitées dans les idées de repas proposées par l’IA. Ne remplace pas la vigilance en cas d’allergie sévère.';

  @override
  String get dietaryPreferencesAllergiesSectionTitle =>
      'ALLERGIES & INTOLÉRANCES';

  @override
  String get dietaryPreferencesDietHalal => 'Halal';

  @override
  String get dietaryPreferencesDietKosher => 'Kasher';

  @override
  String get dietaryPreferencesDietNone => 'Aucune restriction';

  @override
  String get dietaryPreferencesDietPescetarian => 'Pescétarien';

  @override
  String get dietaryPreferencesDietSectionTitle => 'RÉGIME';

  @override
  String get dietaryPreferencesDietVegan => 'Végétalien';

  @override
  String get dietaryPreferencesDietVegetarian => 'Végétarien';

  @override
  String get dietaryPreferencesOtherAllergyHint => 'Autre allergie...';

  @override
  String get dietaryPreferencesSaveButton => 'Enregistrer';

  @override
  String get dietaryPreferencesSavedSnackbar => 'Préférences enregistrées !';

  @override
  String get dietaryPreferencesTitle => 'Préférences alimentaires';

  @override
  String get foodSearchAddManuallyButton =>
      'Aucun résultat ? Ajouter manuellement';

  @override
  String get foodSearchFieldHint => 'Ex. yaourt nature, poulet rôti...';

  @override
  String get foodSearchInitialPrompt =>
      'Tape le nom d\'un aliment pour chercher dans la base Open Food Facts.';

  @override
  String foodSearchKcalPer100g(String value) {
    return '$value kcal / 100 g';
  }

  @override
  String foodSearchNoResults(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get foodSearchTitle => 'Rechercher un aliment';

  @override
  String get forgotPasswordBackToLogin => 'Retour à la connexion';

  @override
  String get forgotPasswordEmailHint => 'exemple@email.com';

  @override
  String get forgotPasswordEmailLabel => 'Adresse e-mail';

  @override
  String get forgotPasswordErrorEmailRequired =>
      'Veuillez entrer votre adresse e-mail.';

  @override
  String get forgotPasswordSubmitButton => 'Envoyer le lien';

  @override
  String get forgotPasswordSubtitle =>
      'Ne vous inquiétez pas, cela arrive.\nEntrez votre email pour recevoir un\nlien de réinitialisation.';

  @override
  String get forgotPasswordSuccessMessage =>
      'Lien de réinitialisation envoyé ! Vérifiez vos emails.';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get helpCenterAccountQ1Answer =>
      'Va dans Profil > Compte pour modifier tes informations, ou Profil > Mes objectifs pour ajuster ton objectif (perte de poids, prise de muscle, maintien) et tes données physiques.';

  @override
  String get helpCenterAccountQ1Question =>
      'Comment modifier mon profil ou mes objectifs ?';

  @override
  String get helpCenterAccountQ2Answer =>
      'Ton abonnement est géré directement par l’App Store ou le Google Play Store (selon ton appareil), pas par l’app elle-même. Rends-toi dans les réglages d’abonnements de ton compte Apple/Google pour le modifier ou le résilier.';

  @override
  String get helpCenterAccountQ2Question =>
      'Comment gérer ou annuler mon abonnement PRO ?';

  @override
  String helpCenterAccountQ3Answer(String supportEmail) {
    return 'Écris-nous à $supportEmail depuis l’adresse email associée à ton compte, on s’occupe de la suppression de tes données.';
  }

  @override
  String get helpCenterAccountQ3Question => 'Comment supprimer mon compte ?';

  @override
  String get helpCenterAppBarTitle => 'Centre d’aide';

  @override
  String get helpCenterCoachQ1Answer =>
      'Depuis l’onglet Coach, appuie sur le bouton \"Coach IA\" en bas de l’écran pour ouvrir le chat. Tu peux lui poser des questions sur ta nutrition, tes objectifs ou lui demander des conseils.';

  @override
  String get helpCenterCoachQ1Question => 'Comment parler au Coach IA ?';

  @override
  String get helpCenterCoachQ2Answer =>
      'L’onglet Coach propose des idées de repas générées selon ton profil et ton objectif. Appuie sur \"Tout voir\" pour la liste complète, puis sur l’icône de rafraîchissement (ou tire l’écran vers le bas) pour en générer de nouvelles.';

  @override
  String get helpCenterCoachQ2Question =>
      'Comment obtenir de nouvelles idées de repas ?';

  @override
  String get helpCenterContactButtonLabel => 'Contacter le support';

  @override
  String get helpCenterMailtoSubject => 'Question AI Health Chef';

  @override
  String get helpCenterMealsQ1Answer =>
      'Depuis le Dashboard, appuie sur le bouton caméra en bas à droite pour prendre en photo ton assiette. L’IA identifie les ingrédients et estime les calories et macros ; tu peux ajuster les quantités, ajouter ou retirer un ingrédient avant de valider.';

  @override
  String get helpCenterMealsQ1Question => 'Comment enregistrer un repas ?';

  @override
  String get helpCenterMealsQ2Answer =>
      'L’analyse est faite par un modèle d’IA (Google Gemini) à partir de la photo : c’est une estimation, pas une mesure exacte. Ajuste les quantités si besoin, ou ajoute un ingrédient manuellement avec ses valeurs exactes via \"Ajouter un ingrédient\".';

  @override
  String get helpCenterMealsQ2Question =>
      'L’estimation des calories est-elle exacte ?';

  @override
  String get helpCenterMealsQ3Answer =>
      'Le Dashboard affiche le \"Journal des repas\" du jour, avec les totaux de calories et macros. Il se réinitialise chaque jour à minuit.';

  @override
  String get helpCenterMealsQ3Question =>
      'Où voir les repas que j’ai enregistrés aujourd’hui ?';

  @override
  String helpCenterNoMailAppSnackbar(String supportEmail) {
    return 'Aucune app mail configurée. Écris-nous à $supportEmail.';
  }

  @override
  String get helpCenterNotFoundSubtitle =>
      'Écris-nous, on te répond directement.';

  @override
  String get helpCenterNotFoundTitle => 'Tu n’as pas trouvé ta réponse ?';

  @override
  String get helpCenterRemindersQ1Answer =>
      'Va dans Profil > Notifications. Active l’interrupteur du repas souhaité (petit-déjeuner, déjeuner, dîner) et choisis l’heure du rappel en appuyant sur l’horaire affiché.';

  @override
  String get helpCenterRemindersQ1Question =>
      'Comment activer les rappels de repas ?';

  @override
  String get helpCenterRemindersQ2Answer =>
      'Vérifie que les notifications sont autorisées pour l’app dans les réglages de ton téléphone. Sur certains téléphones Android, il faut aussi désactiver l’optimisation de batterie pour l’app afin que les rappels sonnent à l’heure prévue.';

  @override
  String get helpCenterRemindersQ2Question =>
      'Je n’ai reçu aucune notification, que faire ?';

  @override
  String get helpCenterSectionAccountTitle => 'Compte & abonnement';

  @override
  String get helpCenterSectionCoachTitle => 'Coach IA & idées de repas';

  @override
  String get helpCenterSectionMealsTitle => 'Repas & analyse IA';

  @override
  String get helpCenterSectionRemindersTitle => 'Rappels & notifications';

  @override
  String get localAiSettingsCancelButton => 'Annuler';

  @override
  String get localAiSettingsDeleteButton => 'Supprimer';

  @override
  String get localAiSettingsDeleteDialogBody =>
      'Le modèle sera supprimé de ton téléphone. Les fonctionnalités IA repasseront en mode cloud.';

  @override
  String get localAiSettingsDeleteDialogTitle => 'Supprimer le modèle IA';

  @override
  String get localAiSettingsDeleteModelButton => 'Supprimer le modèle';

  @override
  String get localAiSettingsDownloadButton => 'Télécharger';

  @override
  String localAiSettingsDownloadDialogBody(String size) {
    return 'Le modèle pèse environ $size. Nous recommandons une connexion Wi-Fi pour ce téléchargement.';
  }

  @override
  String get localAiSettingsDownloadDialogTitle => 'Télécharger le modèle IA';

  @override
  String localAiSettingsDownloadFailedError(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String localAiSettingsDownloadProgressLabel(String percent) {
    return '$percent%';
  }

  @override
  String get localAiSettingsEnableLabel => 'Activer l\'IA locale';

  @override
  String get localAiSettingsIntro =>
      'Traite tes photos de repas et tes messages du coach directement sur ton téléphone, sans connexion, et sans utiliser le quota IA partagé de l\'app. Fonctionnalité optionnelle : sans elle, tout continue de fonctionner via le cloud comme aujourd\'hui.';

  @override
  String get localAiSettingsLoadError =>
      'Impossible de charger les réglages IA locale.';

  @override
  String get localAiSettingsModelDownloadedLabel => 'Modèle téléchargé';

  @override
  String get localAiSettingsModelNotDownloadedLabel => 'Modèle non téléchargé';

  @override
  String get localAiSettingsTitle => 'IA locale';

  @override
  String get loginContinueWithDiscord => 'Continuer avec Discord';

  @override
  String get loginDividerOrContinueWith => 'OU CONTINUER AVEC';

  @override
  String get loginEmailHint => 'nom@exemple.fr';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginErrorFillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String get loginForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get loginHeaderLabel => 'CONNEXION';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginSignupPrompt => 'Pas encore de compte ? S\'inscrire';

  @override
  String get loginSubmitButton => 'Se connecter';

  @override
  String get loginSubtitle => 'Connectez-vous pour suivre vos objectifs';

  @override
  String get loginWelcomeBackTitle => 'Ravi de vous revoir';

  @override
  String get mealAnalysisAddIngredientButton => 'Ajouter un ingrédient';

  @override
  String get mealAnalysisAddIngredientSheetTitle => 'Ajouter un ingrédient';

  @override
  String get mealAnalysisAddIngredientSubtitle =>
      'Renseigne les valeurs pour la portion que tu ajoutes.';

  @override
  String get mealAnalysisBadgeAi => 'Identifié par l\'IA';

  @override
  String get mealAnalysisBadgeBarcode => 'Trouvé via code-barres';

  @override
  String get mealAnalysisBadgeGluc => 'GLUC';

  @override
  String get mealAnalysisBadgeLip => 'LIP';

  @override
  String get mealAnalysisBadgeManual => 'Saisie manuelle';

  @override
  String get mealAnalysisBadgeProt => 'PROT';

  @override
  String get mealAnalysisDefaultMealName => 'Repas IA';

  @override
  String get mealAnalysisErrorCaloriesInvalid =>
      'Entre les calories de cette portion.';

  @override
  String get mealAnalysisErrorNameRequired => 'Entre le nom de l\'ingrédient.';

  @override
  String get mealAnalysisErrorTitle => 'Oups !';

  @override
  String get mealAnalysisErrorWeightInvalid => 'Entre un poids valide (en g).';

  @override
  String get mealAnalysisFieldCaloriesLabel => 'Calories';

  @override
  String get mealAnalysisFieldNameLabel => 'Nom de l\'ingrédient';

  @override
  String get mealAnalysisFieldWeightLabel => 'Poids';

  @override
  String mealAnalysisGramsValue(String value) {
    return '${value}g';
  }

  @override
  String get mealAnalysisHowItWorksBody =>
      'Notre IA identifie les ingrédients de ton assiette et estime leurs valeurs nutritionnelles. Ajuste les quantités avec + / - si besoin, retire un ingrédient avec l’icône poubelle, puis valide pour l’enregistrer dans ton journal du jour.';

  @override
  String get mealAnalysisHowItWorksConfirm => 'Compris';

  @override
  String get mealAnalysisHowItWorksTitle => 'Comment ça marche ?';

  @override
  String get mealAnalysisIngredientsSubtitle =>
      'Modifiez les quantités si nécessaire';

  @override
  String get mealAnalysisIngredientsTitle => 'Ingrédients';

  @override
  String mealAnalysisKcalValue(String value) {
    return '$value kcal';
  }

  @override
  String get mealAnalysisLoadingBarcode => 'Recherche du produit...';

  @override
  String get mealAnalysisLoadingHint =>
      'Cela prend généralement quelques secondes.';

  @override
  String get mealAnalysisLoadingLabel => 'L\'IA lit l\'étiquette du produit...';

  @override
  String get mealAnalysisLoadingPlate => 'L\'IA analyse votre assiette...';

  @override
  String get mealAnalysisMacroCarbs => 'Glucides';

  @override
  String get mealAnalysisMacroFat => 'Lipides';

  @override
  String get mealAnalysisMacroFiber => 'Fibres';

  @override
  String get mealAnalysisMacroProtein => 'Protéines';

  @override
  String get mealAnalysisMacroSatFat => 'Sat.';

  @override
  String get mealAnalysisMacroSugar => 'Sucres';

  @override
  String get mealAnalysisNutritionSummaryTitle => 'RÉSUMÉ NUTRITIONNEL';

  @override
  String get mealAnalysisRetryButton => 'Réessayer';

  @override
  String get mealAnalysisSaveButton => 'Valider et sauvegarder';

  @override
  String get mealAnalysisSaveSuccessSnackbar =>
      'Repas sauvegardé avec succès !';

  @override
  String get mealAnalysisSubmitButton => 'Ajouter';

  @override
  String get mealAnalysisTitleManual => 'AJOUT MANUEL';

  @override
  String get mealAnalysisTitleMeal => 'ANALYSE DU REPAS';

  @override
  String get mealAnalysisTitleProduct => 'ANALYSE DU PRODUIT';

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
  String mealSuggestionsAddedToShoppingListMessage(String title) {
    return '\"$title\" ajouté à la liste de courses';
  }

  @override
  String mealSuggestionsAdjustPresetMessage(String title) {
    return 'Ajuste ce repas pour mon objectif: $title';
  }

  @override
  String get mealSuggestionsEmptyMessage =>
      'Aucune idée de repas disponible pour le moment.';

  @override
  String get mealSuggestionsLoadError =>
      'Impossible de générer des idées de repas pour le moment.';

  @override
  String get mealSuggestionsRegenerateTooltip => 'Régénérer';

  @override
  String get mealSuggestionsRetryButton => 'Réessayer';

  @override
  String get mealSuggestionsTitle => 'Idées repas';

  @override
  String get notificationSettingsAddButton => 'Ajouter';

  @override
  String get notificationSettingsAddSubmitButton => 'Ajouter';

  @override
  String get notificationSettingsCustomRemindersLoadError =>
      'Impossible de charger tes rappels personnalisés.';

  @override
  String get notificationSettingsCustomRemindersTitle =>
      'RAPPELS PERSONNALISÉS';

  @override
  String get notificationSettingsDisabledLabel => 'Désactivé';

  @override
  String get notificationSettingsFrequencyDaily => 'Chaque jour';

  @override
  String get notificationSettingsFrequencyWeekly => 'Chaque semaine';

  @override
  String get notificationSettingsIntro =>
      'Reçois un rappel pour penser à logguer chacun de tes repas.';

  @override
  String get notificationSettingsLoadError =>
      'Impossible de charger les réglages de notifications.';

  @override
  String get notificationSettingsNameRequiredError =>
      'Donne un nom à ton rappel.';

  @override
  String get notificationSettingsNewReminderTitle => 'Nouveau rappel';

  @override
  String get notificationSettingsNoCustomReminders =>
      'Aucun rappel personnalisé pour l\'instant.';

  @override
  String notificationSettingsReminderAtLabel(String time) {
    return 'Rappel à $time';
  }

  @override
  String get notificationSettingsReminderNameHint =>
      'Ex. Collation, Boire de l\'eau...';

  @override
  String get notificationSettingsReminderNameLabel => 'Nom du rappel';

  @override
  String notificationSettingsReminderWeeklyAtLabel(String day, String time) {
    return 'Rappel $day à $time';
  }

  @override
  String notificationSettingsTimeLabel(String time) {
    return 'Heure : $time';
  }

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsSlotBreakfast => 'Petit-déjeuner';

  @override
  String get notificationSettingsSlotLunch => 'Déjeuner';

  @override
  String get notificationSettingsSlotDinner => 'Dîner';

  @override
  String get notificationSettingsBodyBreakfast =>
      'Pense à prendre en photo ton petit-déjeuner pour le logguer !';

  @override
  String get notificationSettingsBodyLunch =>
      'Pense à prendre en photo ton déjeuner pour le logguer !';

  @override
  String get notificationSettingsBodyDinner =>
      'Pense à prendre en photo ton dîner pour le logguer !';

  @override
  String get nutritionTrends30DaySectionTitle =>
      'Tendance calories · 30 derniers jours';

  @override
  String get nutritionTrendsCaloriesLabel => 'Calories';

  @override
  String get nutritionTrendsCaloriesSectionTitle =>
      'Calories · 7 derniers jours';

  @override
  String get nutritionTrendsCarbsLabel => 'Glucides';

  @override
  String get nutritionTrendsDailyAveragesTitle => 'Moyennes quotidiennes';

  @override
  String get nutritionTrendsDayFri => 'Ven';

  @override
  String get nutritionTrendsDayMon => 'Lun';

  @override
  String get nutritionTrendsDaySat => 'Sam';

  @override
  String get nutritionTrendsDaySun => 'Dim';

  @override
  String get nutritionTrendsDayThu => 'Jeu';

  @override
  String get nutritionTrendsDayTue => 'Mar';

  @override
  String get nutritionTrendsDayWed => 'Mer';

  @override
  String get nutritionTrendsEmptyState =>
      'Pas encore assez de repas enregistrés cette semaine pour afficher des tendances.';

  @override
  String nutritionTrendsErrorMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get nutritionTrendsExtraNutrientsTitle =>
      'Autres nutriments (moyenne/jour)';

  @override
  String get nutritionTrendsFatLabel => 'Lipides';

  @override
  String get nutritionTrendsFiberLabel => 'Fibres';

  @override
  String get nutritionTrendsGoProButton => 'Passer PRO';

  @override
  String get nutritionTrendsMacroDistributionTitle =>
      'Répartition des macros (moyenne)';

  @override
  String get nutritionTrendsProLockedDescription =>
      'Débloque les macros détaillées et les tendances nutritionnelles sur 7 jours.';

  @override
  String get nutritionTrendsProLockedTitle => 'Réservé aux membres PRO';

  @override
  String get nutritionTrendsProteinLabel => 'Protéines';

  @override
  String get nutritionTrendsSatFatLabel => 'Graisses sat.';

  @override
  String get nutritionTrendsSugarLabel => 'Sucres';

  @override
  String get nutritionTrendsTitle => 'Analyses avancées';

  @override
  String get onboardingAgeSectionLabel => 'Votre Âge';

  @override
  String get onboardingAgeUnitSuffix => 'ans';

  @override
  String get onboardingErrorGoalRequired => 'Choisis ton objectif principal.';

  @override
  String get onboardingErrorInvalidAge => 'Entre un âge valide.';

  @override
  String get onboardingErrorInvalidHeight => 'Entre ta taille en cm.';

  @override
  String get onboardingErrorInvalidWeight => 'Entre ton poids.';

  @override
  String onboardingErrorSaveProfile(String error) {
    return 'Impossible d\'enregistrer le profil : $error';
  }

  @override
  String get onboardingErrorSexRequired => 'Choisis ton sexe pour continuer.';

  @override
  String get onboardingGoalGainMuscle => 'Prendre de la masse';

  @override
  String get onboardingGoalGainMuscleDescription =>
      'Augmenter l\'apport pour prendre du muscle.';

  @override
  String get onboardingGoalLoseWeight => 'Perdre du poids';

  @override
  String get onboardingGoalLoseWeightDescription =>
      'Réduire l\'apport calorique et brûler les graisses.';

  @override
  String get onboardingGoalMaintain => 'Maintenir mon poids';

  @override
  String get onboardingGoalMaintainDescription =>
      'Équilibrer les macros pour une santé stable.';

  @override
  String get onboardingGoalSectionLabel => 'Quel est votre objectif ?';

  @override
  String get onboardingHeightSectionLabel => 'Votre Taille';

  @override
  String get onboardingSexFemale => 'Femme';

  @override
  String get onboardingSexMale => 'Homme';

  @override
  String get onboardingSexOther => 'Autre';

  @override
  String get onboardingSexSectionLabel => 'Vous êtes...';

  @override
  String get onboardingStepIndicator => 'Étape 1 sur 2';

  @override
  String get onboardingSubmitButton => 'Calculer mon plan';

  @override
  String get onboardingSubtitle =>
      'Ces informations permettent à notre IA de calculer votre besoin calorique précis.';

  @override
  String get onboardingTitle => 'Apprenons à nous connaître';

  @override
  String get onboardingWeightSectionLabel => 'Votre Poids';

  @override
  String get paywallBadgePopular => 'POPULAIRE';

  @override
  String get paywallBenefitAdsFreeSubtitle =>
      'Une expérience fluide, premium et concentrée.';

  @override
  String get paywallBenefitAdsFreeTitle => 'Sans publicité';

  @override
  String get paywallBenefitAnalyticsSubtitle =>
      'Macros détaillées et tendances nutritionnelles.';

  @override
  String get paywallBenefitAnalyticsTitle => 'Analyses avancées';

  @override
  String get paywallBenefitCoachSubtitle =>
      'Recevez des recommandations adaptées à votre objectif.';

  @override
  String get paywallBenefitCoachTitle => 'Coach de repas personnel';

  @override
  String get paywallBenefitPhotoSubtitle =>
      'Analysez autant de repas que nécessaire, sans limite.';

  @override
  String get paywallBenefitPhotoTitle => 'Reconnaissance Photo Illimitée';

  @override
  String get paywallChooseForfaitLabel => 'CHOISISSEZ VOTRE FORFAIT';

  @override
  String get paywallDemoModeNotice =>
      'Mode démo : les achats sont simulés, aucun paiement réel n\'est effectué.';

  @override
  String get paywallHeaderBadge => 'AI-HEALTH-CHEF PRO';

  @override
  String get paywallPeriodMonth => '/ mois';

  @override
  String get paywallPeriodWeek => '/ semaine';

  @override
  String get paywallPeriodYear => '/ an';

  @override
  String get paywallPlanAnnualTitle => 'Annuel';

  @override
  String get paywallPlanLifetimeTitle => 'À vie';

  @override
  String get paywallPlanMonthlyTitle => 'Mensuel';

  @override
  String get paywallPlanWeeklyTitle => 'Hebdomadaire';

  @override
  String get paywallPreviewConfigPending =>
      'Aperçu — configuration RevenueCat en attente';

  @override
  String get paywallPreviewDemoMode => 'Aperçu — achat simulé en mode démo';

  @override
  String get paywallRestoreButton => 'Restaurer mes achats';

  @override
  String paywallRestoreError(String error) {
    return 'Impossible de restaurer les achats : $error';
  }

  @override
  String get paywallRestoreNone => 'Aucun achat actif trouvé pour ce compte.';

  @override
  String get paywallRestoreSuccess =>
      'Achat restauré, ton accès PRO est actif.';

  @override
  String paywallSelectionSummary(String title, String price, String period) {
    return 'Sélection : $title • $price $period';
  }

  @override
  String get paywallSubtitle =>
      'Libérez tout le potentiel de votre nutrition avec l\'intelligence artificielle de pointe.';

  @override
  String get paywallTitle => 'Passez au niveau supérieur';

  @override
  String get paywallUnlockButton => 'Débloquer AI Health Chef PRO';

  @override
  String get profileAboutSubtitle => 'Version et informations';

  @override
  String get profileAboutTitle => 'À propos';

  @override
  String get profileAccountSubtitle => 'Informations personnelles';

  @override
  String get profileAccountTitle => 'Compte';

  @override
  String get profileActiveBadge => 'Actif';

  @override
  String get profileAdvancedAnalyticsSubtitle =>
      'Macros détaillées et tendances nutritionnelles';

  @override
  String get profileAdvancedAnalyticsTitle => 'Analyses avancées';

  @override
  String get profileAgeLabel => 'Âge';

  @override
  String profileAgeValue(int age) {
    return '$age ans';
  }

  @override
  String profileCoachSubtitle(String tone) {
    return 'Ton : $tone';
  }

  @override
  String get profileCoachTitle => 'Coach IA';

  @override
  String get profileCurrentWeightLabel => 'Poids actuel';

  @override
  String get profileDefaultUserName => 'Utilisateur';

  @override
  String profileDietaryPrefsSubtitleWithAllergies(String dietType, int count) {
    return '$dietType · $count allergie(s)';
  }

  @override
  String get profileDietaryPrefsTitle => 'Préférences alimentaires';

  @override
  String get profileExportJournalSubtitle => 'Partager mes repas (CSV)';

  @override
  String get profileExportJournalTitle => 'Exporter mon journal';

  @override
  String get profileGoalLabel => 'Objectif';

  @override
  String get profileGoalsSubtitle => 'Calories et macros';

  @override
  String get profileGoalsTitle => 'Mes objectifs';

  @override
  String get profileHelpCenterSubtitle => 'FAQ, guides et tutoriels';

  @override
  String get profileHelpCenterTitle => 'Centre d’aide';

  @override
  String get profileLanguageTitle => 'Langue';

  @override
  String profileLoadError(String error) {
    return 'Impossible de charger le profil : $error';
  }

  @override
  String get profileLocalAiSubtitleDefault => 'Scan et chat sur l\'appareil';

  @override
  String get profileLocalAiSubtitleDisabled => 'Désactivée';

  @override
  String get profileLocalAiSubtitleEnabled => 'Activée';

  @override
  String get profileLocalAiSubtitleEnabledNotDownloaded =>
      'Activée · à télécharger';

  @override
  String get profileLocalAiTitle => 'IA locale';

  @override
  String get profileLogoutButton => 'Se déconnecter';

  @override
  String profileLogoutError(String error) {
    return 'Erreur lors de la déconnexion : $error';
  }

  @override
  String get profileNotificationsSubtitle => 'Rappels repas et suivi';

  @override
  String get profileNotificationsTitle => 'Notifications';

  @override
  String get profileProBadge => 'PRO';

  @override
  String get profileProBadgeHeader => 'Pro';

  @override
  String get profileSectionGeneral => 'GÉNÉRAL';

  @override
  String get profileSectionPersonalization => 'PERSONNALISATION';

  @override
  String get profileSectionSupport => 'ASSISTANCE';

  @override
  String get profileSecurityComingSoonMessage =>
      'Les réglages de sécurité et confidentialité arrivent bientôt.';

  @override
  String get profileSecuritySubtitle => 'Données et sécurité';

  @override
  String get profileSecurityTitle => 'Sécurité et Confidentialité';

  @override
  String get profileSubscriptionSubtitle => 'Plan PRO et facturation';

  @override
  String get profileSubscriptionTitle => 'Abonnement';

  @override
  String get profileTargetWeightLabel => 'Poids cible';

  @override
  String get profileTermsSubtitle => 'CGU et mentions légales';

  @override
  String get profileTermsTitle => 'Conditions d’utilisation';

  @override
  String get profileTitle => 'MON PROFIL';

  @override
  String get profileUnknownUser => 'Utilisateur inconnu';

  @override
  String get profileVersionText => 'AI Health Chef v1.0.0';

  @override
  String get profileWeightTrackingSubtitle => 'Voir ma courbe de progression';

  @override
  String get profileWeightTrackingTitle => 'Suivi du poids';

  @override
  String profileWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get shoppingListClearCheckedButton => 'Retirer les articles cochés';

  @override
  String get shoppingListEmptyState =>
      'Votre liste de courses est vide. Ajoutez des idées depuis le Coach IA.';

  @override
  String get shoppingListTitle => 'Liste de courses';

  @override
  String get signupAlreadyMember => 'Déjà membre ?';

  @override
  String get signupDividerOrSignUpWith => 'OU S\'INSCRIRE AVEC';

  @override
  String get signupEmailHint => 'jean.dupont@exemple.fr';

  @override
  String get signupEmailLabel => 'ADRESSE E-MAIL';

  @override
  String get signupErrorAcceptTerms =>
      'Vous devez accepter les conditions d\'utilisation.';

  @override
  String get signupErrorFillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String get signupFullNameHint => 'Jean Dupont';

  @override
  String get signupFullNameLabel => 'NOM COMPLET';

  @override
  String get signupHeaderLabel => 'CRÉER UN COMPTE';

  @override
  String get signupLoginLink => 'Se connecter';

  @override
  String get signupPasswordLabel => 'MOT DE PASSE';

  @override
  String get signupSecureDataNotice => 'données cryptées & sécurisées';

  @override
  String get signupSubmitButton => 'S\'inscrire';

  @override
  String get signupSubtitle =>
      'Rejoignez-nous pour transformer votre nutrition avec intelligence artificielle.';

  @override
  String get signupSuccessCheckEmail =>
      'Compte créé ! Vérifiez vos emails pour confirmer.';

  @override
  String get signupTermsAcceptance =>
      'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité';

  @override
  String get termsAppBarTitle => 'Conditions d’utilisation';

  @override
  String get termsDraftBanner =>
      'Brouillon : ce document décrit honnêtement le service, mais n’a pas encore été relu par un professionnel du droit et l’identité légale de l’éditeur reste à compléter. À finaliser avant toute publication publique de l’app.';

  @override
  String termsLastUpdated(String date) {
    return 'Dernière mise à jour : $date';
  }

  @override
  String get termsSection10Body =>
      'L’Application est fournie « en l’état ». L’éditeur ne garantit pas l’exactitude, la disponibilité continue ou l’absence d’erreur du service, notamment des estimations générées par IA. L’usage de l’Application se fait sous ta seule responsabilité.';

  @override
  String get termsSection10Title => '10. Responsabilité';

  @override
  String termsSection11Body(String supportEmail) {
    return 'Tu peux cesser d’utiliser l’Application et demander la suppression de ton compte à tout moment en écrivant à $supportEmail. L’éditeur peut suspendre ou supprimer un compte en cas d’usage abusif ou de non-respect des présentes CGU.';
  }

  @override
  String get termsSection11Title => '11. Résiliation';

  @override
  String get termsSection12Body =>
      'Les présentes CGU peuvent évoluer, notamment en fonction des fonctionnalités ajoutées à l’Application. La version en vigueur est toujours celle consultable dans l’Application.';

  @override
  String get termsSection12Title => '12. Modification des CGU';

  @override
  String get termsSection13Body =>
      'Les présentes CGU sont soumises au droit français.';

  @override
  String get termsSection13Title => '13. Droit applicable';

  @override
  String termsSection14Body(String supportEmail) {
    return 'Pour toute question relative à ces CGU ou à tes données : $supportEmail.';
  }

  @override
  String get termsSection14Title => '14. Contact';

  @override
  String termsSection1Body(String supportEmail) {
    return 'Éditeur : [Nom de l’éditeur à compléter] — projet actuellement développé à titre personnel, sans société immatriculée à ce jour.\nContact : $supportEmail\nHébergement des données et du backend : Supabase Inc. (infrastructure cloud tierce). Application distribuée via l’App Store (Apple) et le Google Play Store.';
  }

  @override
  String get termsSection1Title => '1. Mentions légales';

  @override
  String get termsSection2Body =>
      'Les présentes Conditions d’Utilisation (« CGU ») régissent l’accès et l’usage de l’application mobile AI Health Chef (« l’Application »). En créant un compte ou en utilisant l’Application, tu acceptes l’intégralité des présentes CGU.';

  @override
  String get termsSection2Title => '2. Objet';

  @override
  String get termsSection3Body =>
      'AI Health Chef permet de : suivre ses repas et ses macronutriments au quotidien ; analyser une photo de repas via intelligence artificielle pour estimer les ingrédients et valeurs nutritionnelles ; échanger avec un coach nutritionnel conversationnel basé sur l’IA ; recevoir des idées de repas personnalisées ; configurer des rappels de repas ; et, via un abonnement PRO optionnel, débloquer des fonctionnalités additionnelles.';

  @override
  String get termsSection3Title => '3. Description du service';

  @override
  String get termsSection4Body =>
      'AI Health Chef fournit des informations et estimations à titre purement informatif et ne constitue en aucun cas un avis médical, un diagnostic ou une prescription. Les calculs de calories, macros et objectifs nutritionnels sont des estimations générales. Consulte un médecin ou un·e diététicien·ne avant tout changement alimentaire significatif, en particulier en cas de pathologie, de grossesse, ou de trouble du comportement alimentaire. L’Application ne doit pas être utilisée comme seul outil de suivi dans un contexte médical.';

  @override
  String get termsSection4Title => '4. Ce n’est pas un avis médical';

  @override
  String get termsSection5Body =>
      'Les ingrédients détectés sur photo, les valeurs nutritionnelles estimées, les réponses du coach IA et les idées de repas sont générés par des modèles d’IA tiers (actuellement Google Gemini) et peuvent contenir des erreurs, imprécisions ou approximations. Vérifie et ajuste les informations avant de t’y fier, en particulier en cas d’allergie ou de restriction alimentaire.';

  @override
  String get termsSection5Title =>
      '5. Contenu généré par intelligence artificielle';

  @override
  String get termsSection6Body =>
      'L’utilisation de l’Application nécessite la création d’un compte. Tu es responsable de l’exactitude des informations fournies et de la confidentialité de tes identifiants de connexion. Toute activité réalisée depuis ton compte est présumée effectuée par toi.';

  @override
  String get termsSection6Title => '6. Compte utilisateur';

  @override
  String get termsSection7Body =>
      'Certaines fonctionnalités sont réservées aux utilisateurs abonnés (« PRO »). L’achat, le renouvellement automatique et l’annulation de l’abonnement sont intégralement gérés par la plateforme de paiement de ton appareil (App Store ou Google Play), pas directement par l’éditeur. L’abonnement se renouvelle automatiquement sauf annulation au moins 24h avant la fin de la période en cours, depuis les réglages de ton compte Apple ou Google. Les demandes de remboursement relèvent des politiques d’Apple/Google, pas de l’éditeur.';

  @override
  String get termsSection7Title => '7. Abonnement PRO';

  @override
  String termsSection8Body(String supportEmail) {
    return 'L’Application traite notamment : ton email et ton mot de passe (authentification) ; des données de profil santé (sexe, âge, poids, taille, objectif) ; les photos de repas que tu prends et les données nutritionnelles associées ; ta photo de profil ; et l’historique de tes échanges avec le coach IA. Ces données sont utilisées uniquement pour fournir le service (calcul de tes objectifs, analyse de tes repas, suivi de ton historique) et sont hébergées par Supabase. Les photos de repas sont transmises à Google (modèle Gemini) le temps de l’analyse. Aucune donnée n’est vendue à des tiers. Tu peux demander l’accès, la rectification ou la suppression de tes données à tout moment en écrivant à $supportEmail.';
  }

  @override
  String get termsSection8Title => '8. Données personnelles';

  @override
  String get termsSection9Body =>
      'Le nom, le logo et les éléments graphiques de l’Application appartiennent à l’éditeur. Le contenu que tu crées (photos, messages) reste ta propriété ; tu accordes à l’éditeur le droit de le traiter uniquement dans le cadre du fonctionnement du service (ex. envoi à un fournisseur d’IA pour analyse).';

  @override
  String get termsSection9Title => '9. Propriété intellectuelle';

  @override
  String get svcErrorCompressImage => 'Impossible de compresser l\'image.';

  @override
  String svcErrorAnalyzeMeal(String error) {
    return 'Erreur lors de l\'analyse IA : $error';
  }

  @override
  String svcErrorAnalyzeProduct(String error) {
    return 'Erreur lors de l\'analyse du produit : $error';
  }

  @override
  String svcErrorCoachChat(String error) {
    return 'Erreur de connexion avec le Coach IA : $error';
  }

  @override
  String svcErrorMealSuggestions(String error) {
    return 'Erreur lors de la génération des idées de repas : $error';
  }

  @override
  String get svcErrorAuthRequired =>
      'Vous devez être connecté pour effectuer cette action.';

  @override
  String get svcErrorInvalidCredentials => 'Email ou mot de passe incorrect.';

  @override
  String svcErrorSignup(String error) {
    return 'Erreur lors de l\'inscription : $error';
  }

  @override
  String svcErrorSaveProfile(String error) {
    return 'Erreur lors de la sauvegarde du profil : $error';
  }

  @override
  String svcErrorSavePreferences(String error) {
    return 'Erreur lors de la sauvegarde des préférences : $error';
  }

  @override
  String svcErrorSaveCoachTone(String error) {
    return 'Erreur lors de la sauvegarde du ton du Coach : $error';
  }

  @override
  String get svcErrorProcessImage => 'Impossible de traiter l\'image.';

  @override
  String svcErrorUploadPhoto(String error) {
    return 'Erreur lors de l\'envoi de la photo : $error';
  }

  @override
  String svcErrorFetchProfile(String error) {
    return 'Erreur lors de la récupération du profil : $error';
  }

  @override
  String get svcErrorResetPassword => 'Erreur lors de l\'envoi de l\'email.';

  @override
  String svcErrorOAuth(String provider, String error) {
    return 'Erreur de connexion avec $provider : $error';
  }

  @override
  String svcErrorProductLookupNetwork(String error) {
    return 'Impossible de contacter la base de données produits : $error';
  }

  @override
  String svcErrorProductLookupHttp(String status) {
    return 'Erreur réseau lors de la recherche du produit ($status).';
  }

  @override
  String get svcErrorProductNotFound =>
      'Produit introuvable pour ce code-barres. Essaie une photo du produit, ou ajoute-le manuellement.';

  @override
  String svcErrorLocalAiUnexpectedResponse(String response) {
    return 'Réponse IA locale inattendue : $response';
  }

  @override
  String get svcErrorHuggingFaceToken =>
      'Impossible de récupérer le token Hugging Face.';

  @override
  String get weightTrendCurrentLabel => 'Poids actuel';

  @override
  String get weightTrendEmptyState =>
      'Aucune pesée enregistrée. Ajoutez votre premier poids pour voir votre progression.';

  @override
  String weightTrendErrorMessage(String error) {
    return 'Erreur de chargement : $error';
  }

  @override
  String weightTrendKgValue(String value) {
    return '$value kg';
  }

  @override
  String get weightTrendLogButton => 'Enregistrer mon poids';

  @override
  String get weightTrendLogSheetSaveButton => 'Enregistrer';

  @override
  String get weightTrendLogSheetTitle => 'Nouvelle pesée';

  @override
  String get weightTrendTargetLabel => 'Objectif';

  @override
  String get weightTrendTitle => 'Suivi du poids';

  @override
  String get weightTrendWeeklyReminderAddedMessage =>
      'Rappel de pesée hebdomadaire programmé.';

  @override
  String get weightTrendWeeklyReminderButton =>
      'Me rappeler de me peser chaque semaine';

  @override
  String get weightTrendWeeklyReminderName => 'Pesée hebdomadaire';
}
