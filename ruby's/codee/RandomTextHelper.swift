import UIKit

struct RandomTextHelper {
    static let items: [(titleKey: String, descriptionKey: String)] = [
        ("RandomText_know_me_better_title", "RandomText_know_me_better_desc"),
        ("RandomText_guess_who_title", "RandomText_guess_who_desc"),
        ("RandomText_confess_it_title", "RandomText_confess_it_desc"),
        ("RandomText_spill_it_title", "RandomText_spill_it_desc"),
        ("RandomText_no_chill_zone_title", "RandomText_no_chill_zone_desc"),
        ("RandomText_flex_or_flop_title", "RandomText_flex_or_flop_desc"),
        ("RandomText_who_roasted_me_title", "RandomText_who_roasted_me_desc"),
        ("RandomText_unmask_thoughts_title", "RandomText_unmask_thoughts_desc"),
        ("RandomText_no_names_just_truths_title", "RandomText_no_names_just_truths_desc")
    ]
    
    static func setRandomTitleAndDescription(titleLabel: UILabel, descriptionLabel: UILabel) {
        guard let item = items.randomElement() else { return }
        titleLabel.text = NSLocalizedString(item.titleKey, comment: "")
        descriptionLabel.text = NSLocalizedString(item.descriptionKey, comment: "")
    }
}
