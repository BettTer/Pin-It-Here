
//
//  ContentStrings.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-02.
//

import Foundation

public enum ContentStrings {
    /// Update bundle if you need to change app language
//    static var bundle: Bundle?
//    static var LocalizableFileName = "Localizable"
    
    static let bundle: Bundle = {
        return Bundle.module
    }()
    static let LocalizableFileName = "Localizable"
    
    // MARK: - Data
    public static var DiscordInviteLink: String {
        return ContentStrings.tr(LocalizableFileName, "DiscordInviteLink")
    }
    
    // MARK: - Title
    public static var Plans: String {
        return ContentStrings.tr(LocalizableFileName, "Plans")
    }
    public static var StartANewPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Start")
    }
    public static var More: String {
        return ContentStrings.tr(LocalizableFileName, "More")
    }
    public static var About: String {
        return ContentStrings.tr(LocalizableFileName, "About")
    }
    public static var Introduction: String {
        return ContentStrings.tr(LocalizableFileName, "Introduction")
    }
    public static var Detail: String {
        return ContentStrings.tr(LocalizableFileName, "Detail")
    }
    public static var Setting: String {
        return ContentStrings.tr(LocalizableFileName, "Setting")
    }
    public static var ManageNotification: String {
        return ContentStrings.tr(LocalizableFileName, "ManageNotification")
    }
    
    // MARK: - Text
    public static var Times: String {
        return ContentStrings.tr(LocalizableFileName, "Times")
    }
    public static var Days: String {
        return ContentStrings.tr(LocalizableFileName, "Days")
    }
    public static var Top: String {
        return ContentStrings.tr(LocalizableFileName, "Top")
    }
    public static var Important: String {
        return ContentStrings.tr(LocalizableFileName, "Important")
    }
    public static var Ordinary: String {
        return ContentStrings.tr(LocalizableFileName, "Ordinary")
    }
    public static var Notification: String {
        return ContentStrings.tr(LocalizableFileName, "Notification")
    }
    public static var Preview: String {
        return ContentStrings.tr(LocalizableFileName, "Preview")
    }
    public static var Widget_Small: String {
        return ContentStrings.tr(LocalizableFileName, "Widget_Small")
    }
    public static var Widget_Medium: String {
        return ContentStrings.tr(LocalizableFileName, "Widget_Medium")
    }
    public static var Widget_Large: String {
        return ContentStrings.tr(LocalizableFileName, "Widget_Large")
    }
    
    public static var NotificationTime: String {
        return ContentStrings.tr(LocalizableFileName, "Notification Time")
    }
    public static var EarlyReminders: String {
        return ContentStrings.tr(LocalizableFileName, "Early Reminders")
    }
    public static var SetUpPlanExpirationNotifications: String {
        return ContentStrings.tr(LocalizableFileName, "SetUpPlanExpirationNotifications")
    }
    public static var DailySummaryNotification: String {
        return ContentStrings.tr(LocalizableFileName, "Daily Summary Notification")
    }
    public static var EnableDailySummaryNotification: String {
        return ContentStrings.tr(LocalizableFileName, "EnableDailySummaryNotification")
    }
    public static var HistoricalSummaryNotifications: String {
        return ContentStrings.tr(LocalizableFileName, "Historical summary notifications")
    }
    public static var UnfinishedPlanReminders: String {
        return ContentStrings.tr(LocalizableFileName, "Unfinished Plan Reminders")
    }
    public static var UnfinishedPlanReminderContent_OneTime: String {
        return ContentStrings.tr(LocalizableFileName, "Unfinished Plan Reminder Content_One-time")
    }
    public static var UnfinishedPlanReminderContent: String {
        return ContentStrings.tr(LocalizableFileName, "Unfinished Plan Reminder Content")
    }
    public static var ExpirationNotice: String {
        return ContentStrings.tr(LocalizableFileName, "Expiration Notice")
    }
    public static var YourPlanHasExpired: String {
        return ContentStrings.tr(LocalizableFileName, "Your plan has expired")
    }
    public static var YourOneTimePlanHasExpired: String {
        return ContentStrings.tr(LocalizableFileName, "Your one-time plan has expired")
    }
    
    public static var JoinOur: String {
        return ContentStrings.tr(LocalizableFileName, "Join our")
    }
    public static var Discord: String {
        return ContentStrings.tr(LocalizableFileName, "Discord")
    }
    public static var Group: String {
        return ContentStrings.tr(LocalizableFileName, "group")
    }
    public static var IntroductionContent: String {
        return ContentStrings.tr(LocalizableFileName, "IntroductionContent")
    }
    
    
    
    // MARK: - Button
    public static var Done: String {
        return ContentStrings.tr(LocalizableFileName, "Done")
    }
    public static var InAdvance: String {
        return ContentStrings.tr(LocalizableFileName, "In Advance")
    }
    public static var Notice: String {
        return ContentStrings.tr(LocalizableFileName, "Notice")
    }
    public static var None: String {
        return ContentStrings.tr(LocalizableFileName, "None")
    }
    
    // MARK: - Hint
    public static var ExamplePlanName: String {
        return ContentStrings.tr(LocalizableFileName, "Example Plan")
    }
    public static var ExamplePlanNameWithHint: String {
        return ContentStrings.tr(LocalizableFileName, "Example Plan, can be deleted at any time")
    }
    public static var InProgress: String {
        return ContentStrings.tr(LocalizableFileName, "In Progress")
    }
    public static var Finished: String {
        return ContentStrings.tr(LocalizableFileName, "Finished")
    }
    public static var Paused: String {
        return ContentStrings.tr(LocalizableFileName, "Paused")
    }
    public static var Ended: String {
        return ContentStrings.tr(LocalizableFileName, "Ended")
    }
    
    public static var SmallWidget_description: String {
        return ContentStrings.tr(LocalizableFileName, "SmallWidget.description")
    }
    public static var MediumWidget_Single_description: String {
        return ContentStrings.tr(LocalizableFileName, "MediumWidget_Single.description")
    }
    public static var MediumWidget_Group_description: String {
        return ContentStrings.tr(LocalizableFileName, "MediumWidget_Group.description")
    }
    public static var LargeWidget_description: String {
        return ContentStrings.tr(LocalizableFileName, "LargeWidget.description")
    }
    public static var Notification_description: String {
        return ContentStrings.tr(LocalizableFileName, "Notification.description")
    }
    
    // MARK: - Notification
    public static var Left: String {
        return ContentStrings.tr(LocalizableFileName, "Left")
    }
    public static var TargetForThisPeriod: String {
        return ContentStrings.tr(LocalizableFileName, "Target for this period")
    }
    public static var RemainingToBeCompleted: String {
        return ContentStrings.tr(LocalizableFileName, "Remaining to be completed")
    }
    
    // MARK: - PlanTag
    public static var Fitness: String {
        return ContentStrings.tr(LocalizableFileName, "Fitness")
    }
    public static var Gaming: String {
        return ContentStrings.tr(LocalizableFileName, "Gaming")
    }
    public static var Mindfulness: String {
        return ContentStrings.tr(LocalizableFileName, "Mindfulness")
    }
    public static var Personal: String {
        return ContentStrings.tr(LocalizableFileName, "Personal")
    }
    public static var Reading: String {
        return ContentStrings.tr(LocalizableFileName, "Reading")
    }
    public static var Work: String {
        return ContentStrings.tr(LocalizableFileName, "Work")
    }
    public static var Study: String {
        return ContentStrings.tr(LocalizableFileName, "Study")
    }
    public static var Custom: String {
        return ContentStrings.tr(LocalizableFileName, "Custom")
    }
    
    // MARK: - PlanFlowModel
    public static var Importance: String {
        return ContentStrings.tr(LocalizableFileName, "Importance")
    }
    public static var CurrentCycleStartDate: String {
        return ContentStrings.tr(LocalizableFileName, "Current Cycle Start Date")
    }
    public static var CurrentCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Current Cycle")
    }
    public static var CompletedInCurrentCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Completed In Current Cycle")
    }
    public static var NeedToBeCompleted: String {
        return ContentStrings.tr(LocalizableFileName, "Need To Be Completed")
    }
    public static var PausedDuringThisCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Paused During This Cycle")
    }
    public static var ThisCycle: String {
        return ContentStrings.tr(LocalizableFileName, "This Cycle")
    }
    public static var Started: String {
        return ContentStrings.tr(LocalizableFileName, "Started")
    }
    public static var TimeHasPassed: String {
        return ContentStrings.tr(LocalizableFileName, "Time Has Passed")
    }
    public static var CompletedOnce: String {
        return ContentStrings.tr(LocalizableFileName, "Completed Once")
    }
    public static var ThisCycleHasBeenCompleted: String {
        return ContentStrings.tr(LocalizableFileName, "This Cycle Has Been Completed")
    }
    public static var CorrectedCompletionTimes: String {
        return ContentStrings.tr(LocalizableFileName, "Corrected Completion Times")
    }
    public static var Aftercorrection: String {
        return ContentStrings.tr(LocalizableFileName, "After correction")
    }
    public static var Resumed: String {
        return ContentStrings.tr(LocalizableFileName, "Resumed")
    }
    public static var ThisCycleEnded: String {
        return ContentStrings.tr(LocalizableFileName, "This Cycle Ended")
    }
    public static var HistoricalCompletionRecords: String {
        return ContentStrings.tr(LocalizableFileName, "Historical Completion Records")
    }
    public static var AverageCompletionCycleDays: String {
        return ContentStrings.tr(LocalizableFileName, "Average Completion Cycle Days")
    }
    public static var LongestCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Longest Cycle")
    }
    public static var ShortestCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Shortest Cycle")
    }
    
    // MARK: - PlanCompletionStatus
    public static var CompletedAheadOfSchedule: String {
        return ContentStrings.tr(LocalizableFileName, "Completed ahead of schedule")
    }
    public static var CompletedNormally: String {
        return ContentStrings.tr(LocalizableFileName, "Completed normally")
    }
    public static var CompletedLate: String {
        return ContentStrings.tr(LocalizableFileName, "Completed late")
    }
    public static var NotCompleted: String {
        return ContentStrings.tr(LocalizableFileName, "Not completed")
    }
    
    // MARK: - SelectTag_SUIV
    public static var WhatDoYouWantToFocusOn: String {
        return ContentStrings.tr(LocalizableFileName, "What do you want to focus on?")
    }
    public static var PleaseReChooseAType: String {
        return ContentStrings.tr(LocalizableFileName, "Please re-choose a type.")
    }
    public static var ChooseATypeToGetStarted: String {
        return ContentStrings.tr(LocalizableFileName, "Choose a type to get started.")
    }
    
    // MARK: - NameYourPlan_SUIV
    public static var Name: String {
        return ContentStrings.tr(LocalizableFileName, "Name")
    }
    public static var Next: String {
        return ContentStrings.tr(LocalizableFileName, "Next")
    }
    
    // MARK: - SetCycleInfo_SUIV
    public static var SetTheDurationOfThePlanningCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Set the duration of the planning cycle: ")
    }
    public static var SetTheNumberOfGoalsToAchievePerCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Set the number of goals to achieve per cycle:")
    }
    public static var SelectTheNumberOfDaysInThePlanningCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Select the number of days in the planning cycle")
    }
    public static var SelectTheNumberOfGoalsToAchievePerCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Select the number of goals to achieve per cycle")
    }
    
    // MARK: - SetImportantLevel_SUIV
    public static var SetPlanImportance: String {
        return ContentStrings.tr(LocalizableFileName, "Set plan importance:")
    }
    public static var IsThisAOneTimePlan: String {
        return ContentStrings.tr(LocalizableFileName, "Is this a one-time plan?")
    }
    public static var CreateYourNewPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Create your new plan")
    }
    public static var ChoosePlanImportance: String {
        return ContentStrings.tr(LocalizableFileName, "Choose plan importance:")
    }
    public static var YouCanOnlyHaveOnePlanWithTopImportanceNNthisPlanWillBeDisplayedSeparatelyInSomeWidgets: String {
        return ContentStrings.tr(LocalizableFileName, "You can only have one plan with TOP importance. \n\nThis plan will be displayed separately in some widgets.")
    }
    public static var ChooseWhetherItIsAOneTimePlan: String {
        return ContentStrings.tr(LocalizableFileName, "Choose whether it is a one-time plan")
    }
    public static var OneTimePlansDoNotRecurAutomatically: String {
        return ContentStrings.tr(LocalizableFileName, "One-time plans do not recur automatically")
    }
    
    // MARK: - EditPlan_SUIV
    public static var Else: String {
        return ContentStrings.tr(LocalizableFileName, "ELSE")
    }
    public static var CorrectCurrentCompletionCount: String {
        return ContentStrings.tr(LocalizableFileName, "Correct current completion count: ")
    }
    public static var SavedCurrentCompletionCount: String {
        return ContentStrings.tr(LocalizableFileName, "Saved current completion count")
    }
    public static var ChooseCurrentAccurateCompletionCount: String {
        return ContentStrings.tr(LocalizableFileName, "Choose current accurate completion count")
    }
    public static var TagType: String {
        return ContentStrings.tr(LocalizableFileName, "Tag Type")
    }
    public static var CycleInformation: String {
        return ContentStrings.tr(LocalizableFileName, "Cycle information")
    }
    
    // MARK: - LineChartDetail_SUIView
    public static var DetailedHistory: String {
        return ContentStrings.tr(LocalizableFileName, "Detailed history")
    }
    
    // MARK: - PlanFlowDetail_SUIView
    public static var StartANewCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Start a new cycle")
    }
    public static var ContinueWithThePlan: String {
        return ContentStrings.tr(LocalizableFileName, "Continue with the plan")
    }
    public static var CheckInToCompleteTheGoal: String {
        return ContentStrings.tr(LocalizableFileName, "Check in to complete the goal")
    }
    public static var StartedANewCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Started a new cycle")
    }
    public static var ACompletionHasBeenRecorded: String {
        return ContentStrings.tr(LocalizableFileName, "A completion has been recorded")
    }
    public static var DoYouWantToDeleteThisPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Do you want to delete this plan?")
    }
    public static var AreYouSureYouHaveCompletedTheGoalOnce: String {
        return ContentStrings.tr(LocalizableFileName, "Are you sure you have completed the goal once?")
    }
    public static var Cancel: String {
        return ContentStrings.tr(LocalizableFileName, "Cancel")
    }
    public static var Ok: String {
        return ContentStrings.tr(LocalizableFileName, "OK")
    }
    
    // MARK: - SinglePlanOptionMenu
    public static var AutomaticallyDisplayedInTheWidget: String {
        return ContentStrings.tr(LocalizableFileName, "Displayed in the widget")
    }
    public static var Continue: String {
        return ContentStrings.tr(LocalizableFileName, "Continue")
    }
    public static var Pause: String {
        return ContentStrings.tr(LocalizableFileName, "Pause")
    }
    public static var Edit: String {
        return ContentStrings.tr(LocalizableFileName, "Edit")
    }
    public static var Delete: String {
        return ContentStrings.tr(LocalizableFileName, "Delete")
    }
    
    // MARK: - PlanFlowList_SwiftUIView
    public static var ByImportance: String {
        return ContentStrings.tr(LocalizableFileName, "By Importance")
    }
    public static var ByExpirationDate: String {
        return ContentStrings.tr(LocalizableFileName, "By Expiration Date")
    }
    public static var ByType: String {
        return ContentStrings.tr(LocalizableFileName, "By Type")
    }
    public static var FirstPlanHint: String {
        return ContentStrings.tr(LocalizableFileName, "FirstPlanHint")
    }
    
    // MARK: - GlobalRoute
    public static var SelectAType: String {
        return ContentStrings.tr(LocalizableFileName, "Select a type")
    }
    public static var EditYourPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Edit your plan")
    }
    public static var NameYourPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Name your plan")
    }
    public static var RenameYourPlan: String {
        return ContentStrings.tr(LocalizableFileName, "Rename your plan")
    }
    public static var SetYourOwnCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Set your own cycle")
    }
    
    // MARK: - PlanFlowModel
    public static var CompletedThisOneTimePlan: String {
        return ContentStrings.tr(LocalizableFileName, "Completed this one-time plan")
    }
    public static var CompletedThisCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Completed this cycle")
    }
    public static var YouDidNotCompleteThisPlan: String {
        return ContentStrings.tr(LocalizableFileName, "You did not complete this plan 😞")
    }
    public static var YouDidNotCompleteThisPlanInTheLastCycle: String {
        return ContentStrings.tr(LocalizableFileName, "You didn’t finish this plan in the last cycle 😞")
    }
    public static var Remaining: String {
        return ContentStrings.tr(LocalizableFileName, "Remaining")
    }
    public static var Completed: String {
        return ContentStrings.tr(LocalizableFileName, "Completed")
    }
    public static var NextCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Next cycle: ")
    }
    public static var Later: String {
        return ContentStrings.tr(LocalizableFileName, "later")
    }
    
    // MARK: - PlanDataManager
    public static var ExpiresIn3Days: String {
        return ContentStrings.tr(LocalizableFileName, "Expires in 3 days")
    }
    public static var ExpiresIn37Days: String {
        return ContentStrings.tr(LocalizableFileName, "Expires in 3-7 days")
    }
    public static var ExpiresIn714Days: String {
        return ContentStrings.tr(LocalizableFileName, "Expires in 7-14 days")
    }
    public static var ExpiresBeyond14Days: String {
        return ContentStrings.tr(LocalizableFileName, "Expires beyond 14 days")
    }
    
    // MARK: - PustNotificationManager
    public static var PlanName: String {
        return ContentStrings.tr(LocalizableFileName, "Plan Name")
    }
    
    // MARK: - DailySummaryData
    public static var Summary: String {
        return ContentStrings.tr(LocalizableFileName, "Summary")
    }
    public static var Today: String {
        return ContentStrings.tr(LocalizableFileName, "Today")
    }
    public static var ThatDay: String {
        return ContentStrings.tr(LocalizableFileName, "That day")
    }
    public static var TotalNumberOfPlans: String {
        return ContentStrings.tr(LocalizableFileName, "Total number of plans")
    }
    public static var NumberOfPausedPlans: String {
        return ContentStrings.tr(LocalizableFileName, "Number of paused plans")
    }
    public static var RecordOfThatDay: String {
        return ContentStrings.tr(LocalizableFileName, "Record of that day")
    }
    public static var Create: String {
        return ContentStrings.tr(LocalizableFileName, "Create")
    }
    public static var CheckIn: String {
        return ContentStrings.tr(LocalizableFileName, "Check-in")
    }
    public static var CorrectionCompletionTimes: String {
        return ContentStrings.tr(LocalizableFileName, "Correction completion times")
    }
    public static var FishishCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Fishish cycle")
    }
    public static var StartNewCycle: String {
        return ContentStrings.tr(LocalizableFileName, "Start new cycle")
    }
    public static var DoNothing: String {
        return ContentStrings.tr(LocalizableFileName, "DoNothing")
    }
    
    // MARK: - PlanFlowWidgetView_Large
    public static var UntilExpiringPlans: String {
        return ContentStrings.tr(LocalizableFileName, "Until Expiring Plans")
    }
    public static var ExpectedDelay: String {
        return ContentStrings.tr(LocalizableFileName, "Expected Delay")
    }
    public static var OnTrack: String {
        return ContentStrings.tr(LocalizableFileName, "On Track")
    }
    public static var CurrentlyPaused: String {
        return ContentStrings.tr(LocalizableFileName, "Currently Paused")
    }
    
    // MARK: - SinglePlanFlowWidgetView
    public static var PleaseSetThePlanYouWantToDisplay: String {
        return ContentStrings.tr(LocalizableFileName, "Please set the plan you want to display")
    }
    public static var PleaseSetThePlanToTopImportanceNorLongPressTheWidgetToEdit: String {
        return ContentStrings.tr(LocalizableFileName, "Please set the plan to Top importance.\nOr long press the widget to edit")
    }

    // MARK: - SelectSinglePlanConfigurationAppIntent
    public static var SelectAPlanToDisplay: String {
        return ContentStrings.tr(LocalizableFileName, "Select a plan to display")
    }
    public static var PickAPlanWith: String {
        return ContentStrings.tr(LocalizableFileName, "Pick a plan with")
    }
    
    // MARK: - SelectSinglePlanEntryIntentType
    public static var ThisWidgetOnlySupportsSmallAndMediumSizes: String {
        return ContentStrings.tr(LocalizableFileName, "This widget only supports small and medium sizes")
    }
    public static var PleaseTryToReset: String {
        return ContentStrings.tr(LocalizableFileName, "Please try to reset")
    }
    public static var ThePlanYouSelectedIsNotFound: String {
        return ContentStrings.tr(LocalizableFileName, "The plan you selected is not found")
    }
    
    // MARK: - MultiplePlansConfigurationAppIntent
    public static var PlanShownOnTheLeft: String {
        return ContentStrings.tr(LocalizableFileName, "Plan shown on the left")
    }
    public static var PlanShownInTheMiddle: String {
        return ContentStrings.tr(LocalizableFileName, "Plan shown in the middle")
    }
    public static var PlanShownOnTheRight: String {
        return ContentStrings.tr(LocalizableFileName, "Plan shown on the right")
    }

    
    // MARK: - onboarding
    public static var Onboarding: String {
        return ContentStrings.tr(LocalizableFileName, "Onboarding")
    }
    public static var OnboardingItemInfo_Title_1: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Title_1")
    }
    public static var OnboardingItemInfo_Description_1: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Description_1")
    }
    
    public static var OnboardingItemInfo_Title_2: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Title_2")
    }
    public static var OnboardingItemInfo_Description_2: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Description_2")
    }
    
    public static var OnboardingItemInfo_Title_3: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Title_3")
    }
    public static var OnboardingItemInfo_Description_3: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Description_3")
    }
    
    public static var OnboardingItemInfo_Title_4: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Title_4")
    }
    public static var OnboardingItemInfo_Description_4: String {
        return ContentStrings.tr(LocalizableFileName, "OnboardingItemInfo_Description_4")
    }
    
    // MARK: - Crash reportor
    public static var Crash_title: String {
        return ContentStrings.tr(LocalizableFileName, "Crash title")
    }
    public static var Crash_message: String {
        return ContentStrings.tr(LocalizableFileName, "Crash message")
    }
    public static var Crash_yesAnswer: String {
        return ContentStrings.tr(LocalizableFileName, "Crash yesAnswer")
    }
    public static var Crash_noAnswer: String {
        return ContentStrings.tr(LocalizableFileName, "Crash noAnswer")
    }
}

extension ContentStrings {
    static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
//    static func setLanguage(_ language: String?) {
//        if let language = language,
//           let path = Bundle.main.path(forResource: language, ofType: "lproj"),
//           let langBundle = Bundle(path: path) {
//            ContentStrings.bundle = langBundle
//            
//        } else {
//            ContentStrings.bundle = nil // 回退系统语言
//            
//        }
//    }
}

private final class BundleToken {
    
}
