//
//  StaticFunction.swift
//  LOL
//
//  Created by Arpit iOS Dev. on 05/08/24.
//

import Foundation
import UIKit

class ConstantValue {
    
    static var user_name = "username"
    static var name = "name"
    static var avatar_URL = "avatarURL"
    static var is_UserRegistered = "isUserRegistered"
    static var is_UserLink = "isUserLink"
    static var profile_Image = "profileImage"
    static var pauseLinkSwitchState = "pauseLinkSwitchState"
    static var isPurchase = "isPurchase"
}


class LanguageSet {
    static var languageSelected = "selectedLanguage"
}

// NEW
struct Constants {
    static let shared = Constants()
    struct URLs {}
    struct GAME_NAMES {}
    struct Fonts {}
    struct Colors {}
    struct UD {}
    struct Strings {}
    
    static var SUBSCRIPTION_ID = ""
}

var isFromSetting = Bool()
var shouldOpenInbox = false
var isFromInbox: Bool = false
var isInboxNotificationTapped: Bool = false
var isPickedImageFromCamera: Bool = false
var isPremiumScreenFromBottom: Bool = false
var isGame1: Bool = false
var isGame2: Bool = false
var isGame3: Bool = false
var isGame4: Bool = false
var isGame5: Bool = false
var isGame6: Bool = false
var isGame7: Bool = false
var isGame8: Bool = false
var isGame9: Bool = false
var is_all_card_seen: Bool = false
var isBackFromInbox: Bool = false
var shouldRefreshInboxData: Bool = false
var deletedInboxId: String? = nil  // Track deleted inbox ID for immediate UI update
var ispremiumSuccessCallback: Bool = false  // Flag to indicate premium purchase success for UI update
var isUpdateAvailable: Bool = Bool()

var MONTH_PRODUCT_ID = "lol.month.premium"
var WEEK_PRODUCT_ID = "lol.weekly.premium"
var OFFER_WEEK_PRODUCT_ID = "lol.discount.weekly.premium"
var OFFER_MONTH_PRODUCT_ID = "lol.discount.month.premium"
var SUBSCRIPTION_KEY_ID = "9DX569246M"
var PREMIUM_SUCCESS_CALLBACK = "PREMIUM_SUCCESS_CALLBACK"
