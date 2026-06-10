#!/usr/bin/env python3
"""Replace hardcoded English strings in UI files with localized language.text() calls."""
import re, os

ROOT = '/Users/wanna/watch_health/OHeasApp/UI'

# Map of file -> list of (old_string, new_string) replacements
# Each replacement replaces a hardcoded English Text("...") with Text(language.text(.key))
REPLACEMENTS = {
    'TodayView.swift': [
        ('Text("Generating recommendation...")', 'Text(language.text(.generatingRecommendation))'),
        ('Text("Fallback: \\(fallback)")', 'Text("\\(language.text(.fallbackLabel)): \\(fallback)")'),
    ],
    'EffectivenessDashboardView.swift': [
        # Metric tiles
        ('title: "Recommendation adherence"', 'title: language.text(.metricAdherence)'),
        ('title: "Plan completion"', 'title: language.text(.metricPlanCompletion)'),
        ('title: "Experiment completion"', 'title: language.text(.metricExperimentCompletion)'),
        ('title: "Likely helped"', 'title: language.text(.metricLikelyHelped)'),
        ('title: "Data coverage"', 'title: language.text(.metricDataCoverage)'),
        ('title: "Confidence"', 'title: language.text(.metricConfidence)'),
        # ContentUnavailableView
        ('"No effectiveness report"', 'language.text(.noEffectivenessReport)'),
        ('description: Text("Load data or a demo scenario first.")', 'description: Text(language.text(.noEffectivenessDescription))'),
        # Navigation
        ('.navigationTitle("Effectiveness")', '.navigationTitle(language.text(.effectivenessTitle))'),
    ],
    'InsightsTabView.swift': [
        ('title: "Recommendation adherence"', 'title: language.text(.metricAdherence)'),
        ('title: "Plan completion"', 'title: language.text(.metricPlanCompletion)'),
        ('title: "Experiment completion"', 'title: language.text(.metricExperimentCompletion)'),
        ('title: "Likely helped"', 'title: language.text(.metricLikelyHelped)'),
        ('title: "Data coverage"', 'title: language.text(.metricDataCoverage)'),
        ('title: "Confidence"', 'title: language.text(.metricConfidence)'),
    ],
    'HealthPermissionRecoveryView.swift': [
        ('Text("Why HealthKit Permissions Matter")', 'Text(language.text(.whyHealthKitTitle))'),
        ('Text("OHeas reads aggregate sleep, recovery, and activity data from Apple Health. Without permission, the agent cannot build your personal baseline, detect recovery signals, or generate personalized recommendations.")', 'Text(language.text(.permissionWhyDescription))'),
        ('Text("Current Permission Status")', 'Text(language.text(.permissionStatusTitle))'),
        ('Text("How to Fix")', 'Text(language.text(.howToFix))'),
        ('Text("In Settings → Health → Data Access & Devices → OHeas, enable all read categories.")', 'Text(language.text(.permissionFixDescription))'),
        ('.navigationTitle("Health Permissions")', '.navigationTitle(language.text(.healthPermissionsNavTitle))'),
        # Permission descriptions
        ('description: "Needed for recovery baseline and sleep deficit detection."', 'description: language.text(.hkSleepDescription)'),
        ('description: "Core recovery signal. Without it, recovery state is uncertain."', 'description: language.text(.hkHRVDescription)'),
        ('description: "Used alongside HRV to interpret recovery and strain."', 'description: language.text(.hkRHRDescription)'),
        ('description: "Daily activity baseline and low-activity detection."', 'description: language.text(.hkStepsDescription)'),
        ('description: "Caloric expenditure baseline for activity interpretation."', 'description: language.text(.hkEnergyDescription)'),
        ('description: "Time spent exercising per day."', 'description: language.text(.hkExerciseDescription)'),
        ('description: "Workout history for activity pattern mining."', 'description: language.text(.hkWorkoutsDescription)'),
    ],
    'PrivacyView.swift': [
        ('Text("LLM Data Controls")', 'Text(language.text(.llmDataControls))'),
        ('Text("Default behavior sends only aggregate summaries. Raw HealthKit samples stay local unless explicitly enabled.")', 'Text(language.text(.privacyLLMDescription))'),
        ('Text("LLM Payload Preview")', 'Text(language.text(.llmPayloadPreview))'),
        ('Text("OHeas is a lifestyle coaching demo. It avoids medical diagnosis, does not require LLM use, and keeps HealthKit raw samples out of prompts unless the user turns that on.")', 'Text(language.text(.privacyPolicyDescription))'),
        ('Text("Policy")', 'Text(language.text(.policyLabel))'),
        ('.navigationTitle("Privacy")', '.navigationTitle(language.text(.privacyNavTitle))'),
    ],
    'OnboardingView.swift': [
        ('Text("Raw HealthKit samples are off by default and are not uploaded.")', 'Text(language.text(.onboardingRawSamplesNote))'),
        ('Text("AI advice is lifestyle-only. Without consent, OHeas uses local rules.")', 'Text(language.text(.onboardingAINote))'),
        ('Text("OHeas reads aggregate sleep, HRV, resting heart rate, steps, energy, exercise minutes, and workouts. If permission is unavailable, mock or limited mode is used.")', 'Text(language.text(.permissionWhyDescription))'),
    ],
    'BetaAnalyticsDashboardView.swift': [
        ('Text("Local Beta Analytics")', 'Text(language.text(.localBetaAnalytics))'),
        ('Text("Analytics properties are limited to non-sensitive product summaries, never raw health samples.")', 'Text(language.text(.analyticsDescription))'),
        ('.navigationTitle("Beta Analytics")', '.navigationTitle(language.text(.betaAnalyticsNavTitle))'),
    ],
    'BetaFeedbackView.swift': [
        ('Text("You can submit again if you\'d like to update your responses.")', 'Text(language.text(.feedbackResubmitNote))'),
        ('Text("Quick Feedback")', 'Text(language.text(.quickFeedback))'),
        ('Text("These questions help us understand if OHeas is hitting the right balance between helpfulness, clarity, and respect for your attention.")', 'Text(language.text(.feedbackDescription))'),
        ('Text("Beta feedback is stored locally. If analytics consent is enabled, a non-sensitive event is recorded. No raw health data is ever uploaded.")', 'Text(language.text(.feedbackStorageNote))'),
        ('Text("Your feedback helps shape OHeas. Thank you.")', 'Text(language.text(.feedbackThankYou))'),
        ('.navigationTitle("Beta Feedback")', '.navigationTitle(language.text(.betaFeedbackNavTitle))'),
    ],
    'DemoModeView.swift': [
        ('Text("Demo Scenario Builder")', 'Text(language.text(.demoScenarioBuilder))'),
        ('Text("Demo mode writes clearly generated local data to OHeas stores. It does not modify Apple Health.")', 'Text(language.text(.demoDescription))'),
        ('Text("Current Demo")', 'Text(language.text(.currentDemo))'),
        ('.navigationTitle("Demo")', '.navigationTitle(language.text(.demoNavTitle))'),
    ],
    'EvaluationDebugView.swift': [
        ('Text(result.passed ? "Pass" : "Fail")', 'Text(result.passed ? language.text(.passLabel) : language.text(.failLabel))'),
        ('Text("Evaluation Results")', 'Text(language.text(.evaluationResults))'),
        ('Text(result.regressionDetected ? "Regression" : (result.changed ? "Changed" : "Stable"))', 'Text(result.regressionDetected ? language.text(.regressionLabel) : (result.changed ? language.text(.changedLabel) : language.text(.stableLabel)))'),
        ('Text("Prompt Regression")', 'Text(language.text(.promptRegression))'),
        ('.navigationTitle("Evaluation")', '.navigationTitle(language.text(.evaluationNavTitle))'),
    ],
    'SyncStatusView.swift': [
        ('Text("Sync Status")', 'Text(language.text(.syncStatusSection))'),
        ('Text("Cloud sync requires cloud_sync consent and backend configuration. LocalOnly keeps all data on device.")', 'Text(language.text(.syncStatusDescription))'),
        ('.navigationTitle("Sync")', '.navigationTitle(language.text(.syncNavTitle))'),
    ],
    'WeeklyReviewView.swift': [
        ('title: "Recovery"', 'title: language.text(.recoverySection)'),
        ('title: "Activity"', 'title: language.text(.activitySection)'),
        ('title: "Experiment"', 'title: language.text(.experimentSection)'),
        ('title: "Next Week"', 'title: language.text(.nextWeekSection)'),
    ],
}

def process_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
        else:
            print(f"  WARNING: not found: {old[:60]}...")

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    updated = 0
    for filename, replacements in REPLACEMENTS.items():
        filepath = os.path.join(ROOT, filename)
        if os.path.exists(filepath):
            if process_file(filepath, replacements):
                print(f"  Updated: {filename}")
                updated += 1
        else:
            print(f"  SKIP (not found): {filepath}")

    print(f"\nUpdated {updated} files.")

if __name__ == '__main__':
    main()
